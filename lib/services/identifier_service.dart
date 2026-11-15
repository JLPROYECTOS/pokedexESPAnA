import 'dart:math' as math;

import '../models/animal.dart';

class Suggestion {
  const Suggestion({
    required this.animal,
    required this.score,
    required this.matched,
  });

  final Animal animal;

  /// 0..1: parte de la descripcion (ponderada) que encaja con el animal.
  final double score;

  /// Palabras de la descripcion que han coincidido.
  final List<String> matched;
}

/// Identificador por descripcion libre, 100 % offline.
///
/// Normaliza el texto (minusculas, sin tildes, sin plurales ni genero),
/// aplica sinonimos y puntua cada animal segun las palabras que coinciden
/// con sus rasgos. Las palabras raras en el catalogo pesan mas (IDF).
/// Se puede sustituir por un modelo de lenguaje manteniendo la misma firma.
class IdentifierService {
  static const _stopWords = {
    'a', 'al', 'con', 'como', 'de', 'del', 'el', 'en', 'era', 'es', 'he',
    'la', 'las', 'lo', 'los', 'muy', 'o', 'para', 'parece', 'por', 'que',
    'se', 'su', 'tiene', 'tenia', 'un', 'una', 'unos', 'unas', 'vi', 'visto',
    'vive', 'y', 'cerca', 'animal', 'creo', 'algo', 'bastante', 'especie',
    'son', 'sus', 'mas', 'entre', 'tambien', 'familia', 'genero', 'orden',
  };

  /// Sinonimos y variantes -> termino usado en los rasgos del catalogo.
  static const _synonyms = {
    'pajaro': 'ave',
    'pajaros': 'ave',
    'pajarito': 'ave',
    'peces': 'pez',
    'pescado': 'pez',
    'serpiente': 'culebra',
    'bicha': 'culebra',
    'tortuga': 'galapago',
    'arroyo': 'rio',
    'riachuelo': 'rio',
    'ribera': 'rio',
    'laguna': 'charca',
    'estanque': 'charca',
    'sierra': 'montana',
    'monte': 'bosque',
    'chico': 'pequeno',
    'diminuto': 'pequeno',
    'enorme': 'grande',
    'gigante': 'grande',
    'colorado': 'rojo',
    'encarnado': 'rojo',
    'anaranjado': 'naranja',
    'oscuro': 'negro',
    'negruzco': 'negro',
    'pardo': 'marron',
    'castano': 'marron',
    'manchas': 'moteado',
    'manchado': 'moteado',
    'motas': 'moteado',
    'pintas': 'moteado',
    'rabo': 'cola',
    'cuernos': 'cuerno',
    'cornamenta': 'cuerno',
    'noche': 'nocturno',
    'pared': 'muro',
    'paredes': 'muro',
    'tejado': 'torre',
    'campanario': 'torre',
  };

  static const _categoryHintsRaw = {
    'ave': AnimalCategory.ave,
    'mamifero': AnimalCategory.mamifero,
    'reptil': AnimalCategory.reptil,
    'culebra': AnimalCategory.reptil,
    'lagarto': AnimalCategory.reptil,
    'lagartija': AnimalCategory.reptil,
    'galapago': AnimalCategory.reptil,
    'anfibio': AnimalCategory.anfibio,
    'rana': AnimalCategory.anfibio,
    'sapo': AnimalCategory.anfibio,
    'pez': AnimalCategory.pez,
    'tiburon': AnimalCategory.pez,
    'insecto': AnimalCategory.invertebrado,
    'mariposa': AnimalCategory.invertebrado,
    'polilla': AnimalCategory.invertebrado,
    'escarabajo': AnimalCategory.invertebrado,
    'arana': AnimalCategory.invertebrado,
    'libelula': AnimalCategory.invertebrado,
    'abeja': AnimalCategory.invertebrado,
    'avispa': AnimalCategory.invertebrado,
    'mosca': AnimalCategory.invertebrado,
    'saltamontes': AnimalCategory.invertebrado,
    'caracol': AnimalCategory.invertebrado,
    'cangrejo': AnimalCategory.invertebrado,
    'bicho': AnimalCategory.invertebrado,
  };

  static final Map<String, AnimalCategory> _categoryHints = {
    for (final e in _categoryHintsRaw.entries) _canonical(e.key): e.value,
  };

  static String normalize(String text) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    var out = text.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  static String _stem(String word) {
    var w = word;
    if (w.length > 3 && w.endsWith('s')) w = w.substring(0, w.length - 1);
    if (w.length > 3 && (w.endsWith('o') || w.endsWith('a'))) {
      w = w.substring(0, w.length - 1);
    }
    return w;
  }

  static String _canonical(String normalizedWord) =>
      _stem(_synonyms[normalizedWord] ?? normalizedWord);

  static Set<String> _tokens(String text) {
    return normalize(text)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 1 && !_stopWords.contains(w))
        .map(_canonical)
        .toSet();
  }

  // Las fichas escritas a mano tienen rasgos de campo; en el resto se usa
  // el texto de la descripcion.
  static Set<String> _animalTokens(Animal a) => _tokens(
        '${a.commonName} ${a.category.key} ${a.habitat} '
        '${a.keywords.isEmpty ? a.description : a.keywords.join(' ')}',
      );

  List<Animal>? _indexedFor;
  Map<Animal, Set<String>> _index = const {};

  List<Suggestion> identify(
    String description,
    List<Animal> animals, {
    int maxResults = 5,
  }) {
    final query = _tokens(description);
    if (query.isEmpty || animals.isEmpty) return const [];

    if (!identical(_indexedFor, animals)) {
      _index = {for (final a in animals) a: _animalTokens(a)};
      _indexedFor = animals;
    }
    final index = _index;

    // Peso de cada palabra: cuanto menos animales la comparten, mas discrimina.
    double weight(String token) {
      final df = index.values.where((t) => t.contains(token)).length;
      return 1 + math.log(animals.length / (1 + df));
    }

    final weights = {for (final t in query) t: weight(t)};
    final total = weights.values.fold<double>(0, (s, w) => s + w);

    final hinted = query
        .map((t) => _categoryHints[t])
        .whereType<AnimalCategory>()
        .toSet();

    final results = <Suggestion>[];
    index.forEach((animal, tokens) {
      final matched = query.where(tokens.contains).toList();
      if (matched.isEmpty) return;
      var score =
          matched.fold<double>(0, (s, t) => s + weights[t]!) / total;
      // Si el usuario dice "pajaro" y el animal no es un ave, penaliza fuerte.
      if (hinted.isNotEmpty && !hinted.contains(animal.category)) {
        score *= 0.2;
      }
      results.add(Suggestion(animal: animal, score: score, matched: matched));
    });

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(maxResults).toList();
  }
}
