/// Categorias del catalogo. La clave coincide con el campo "category" del JSON.
enum AnimalCategory {
  mamifero('mamifero', 'Mamíferos', 'Mamífero'),
  ave('ave', 'Aves', 'Ave'),
  reptil('reptil', 'Reptiles', 'Reptil'),
  anfibio('anfibio', 'Anfibios', 'Anfibio'),
  pez('pez', 'Peces', 'Pez'),
  invertebrado('invertebrado', 'Invertebrados', 'Invertebrado');

  const AnimalCategory(this.key, this.label, this.singular);
  final String key;
  final String label;
  final String singular;

  static AnimalCategory fromKey(String key) => AnimalCategory.values
      .firstWhere((c) => c.key == key, orElse: () => AnimalCategory.invertebrado);
}

/// Autor y licencia de la fotografia (Wikimedia Commons).
class PhotoCredit {
  const PhotoCredit({
    required this.author,
    required this.license,
    required this.source,
    required this.origin,
  });

  final String author;
  final String license;
  final String source;

  /// De donde procede la foto: Wikimedia Commons o iNaturalist.
  final String origin;

  factory PhotoCredit.fromJson(Map<String, dynamic> json) => PhotoCredit(
        author: (json['author'] ?? '') as String,
        license: (json['license'] ?? '') as String,
        source: (json['source'] ?? '') as String,
        origin: (json['origin'] ?? 'Wikimedia Commons') as String,
      );
}

class Animal {
  const Animal({
    required this.id,
    required this.number,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.family,
    required this.habitat,
    required this.conservation,
    required this.description,
    required this.facts,
    required this.keywords,
    required this.image,
    this.credit,
    this.textSource = '',
  });

  final String id;
  final int number;
  final String commonName;
  final String scientificName;
  final AnimalCategory category;
  final String family;
  final String habitat;

  /// Codigo UICN: LC, NT, VU, EN, CR.
  final String conservation;
  final String description;
  final List<String> facts;

  /// Rasgos de campo (tamano, colores, marcas, comportamiento) que usa
  /// el asistente para identificar por descripcion.
  final List<String> keywords;

  /// Ruta del asset, p. ej. assets/images/lince_iberico.jpg
  final String image;

  final PhotoCredit? credit;

  /// Origen del texto cuando no es propio (p. ej. Wikipedia).
  final String textSource;

  String get numberLabel => '#${number.toString().padLeft(4, '0')}';

  static const _conservationLabels = {
    'LC': 'Preocupación menor',
    'NT': 'Casi amenazado',
    'VU': 'Vulnerable',
    'EN': 'En peligro',
    'CR': 'En peligro crítico',
    'NE': 'Sin datos',
  };

  String get conservationName =>
      _conservationLabels[conservation] ?? conservation;

  String get conservationLabel => conservation == 'NE'
      ? conservationName
      : '$conservationName ($conservation)';

  factory Animal.fromJson(Map<String, dynamic> json, {required int number}) {
    final photo = json['photo'];
    return Animal(
      id: json['id'] as String,
      number: number,
      commonName: json['commonName'] as String,
      scientificName: (json['scientificName'] ?? '') as String,
      category: AnimalCategory.fromKey((json['category'] ?? '') as String),
      family: (json['family'] ?? '') as String,
      habitat: (json['habitat'] ?? '') as String,
      conservation: (json['conservation'] ?? 'NE') as String,
      description: (json['description'] ?? '') as String,
      facts: ((json['facts'] ?? const []) as List).cast<String>(),
      keywords: ((json['keywords'] ?? const []) as List).cast<String>(),
      image: 'assets/images/${json['id']}.jpg',
      credit: photo is Map
          ? PhotoCredit.fromJson(photo.cast<String, dynamic>())
          : null,
      textSource: (json['textSource'] ?? '') as String,
    );
  }
}
