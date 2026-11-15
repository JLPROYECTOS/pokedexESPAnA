/// Categorias del catalogo. La clave coincide con el campo "category" del JSON.
enum AnimalCategory {
  mamifero('mamifero', 'Mamíferos'),
  ave('ave', 'Aves'),
  reptil('reptil', 'Reptiles'),
  anfibio('anfibio', 'Anfibios'),
  pez('pez', 'Peces');

  const AnimalCategory(this.key, this.label);
  final String key;
  final String label;

  static AnimalCategory fromKey(String key) =>
      AnimalCategory.values.firstWhere((c) => c.key == key);
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

  String get numberLabel => '#${number.toString().padLeft(3, '0')}';

  static const _conservationLabels = {
    'LC': 'Preocupación menor',
    'NT': 'Casi amenazado',
    'VU': 'Vulnerable',
    'EN': 'En peligro',
    'CR': 'En peligro crítico',
  };

  String get conservationLabel =>
      '${_conservationLabels[conservation] ?? conservation} ($conservation)';

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] as String,
      number: json['number'] as int,
      commonName: json['commonName'] as String,
      scientificName: json['scientificName'] as String,
      category: AnimalCategory.fromKey(json['category'] as String),
      family: json['family'] as String,
      habitat: json['habitat'] as String,
      conservation: json['conservation'] as String,
      description: json['description'] as String,
      facts: (json['facts'] as List).cast<String>(),
      keywords: (json['keywords'] as List).cast<String>(),
      image: 'assets/images/${json['id']}.jpg',
    );
  }
}
