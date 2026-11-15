/// Registro de un avistamiento: cuando y donde vio el usuario al animal.
class Sighting {
  const Sighting({required this.animalId, required this.date, this.place});

  final String animalId;
  final DateTime date;
  final String? place;

  String get dateLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Map<String, dynamic> toJson() => {
        'animalId': animalId,
        'date': date.toIso8601String(),
        'place': place,
      };

  factory Sighting.fromJson(Map<String, dynamic> json) => Sighting(
        animalId: json['animalId'] as String,
        date: DateTime.parse(json['date'] as String),
        place: json['place'] as String?,
      );
}
