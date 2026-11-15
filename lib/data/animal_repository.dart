import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/animal.dart';

/// Fuente de datos del catalogo. Hoy lee JSON empaquetado en la app;
/// se puede sustituir por una base de datos local o una API sin tocar la UI.
class AnimalRepository {
  Future<List<Animal>> loadAll() async {
    final raw = await rootBundle.loadString('assets/data/animals.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    Map<String, dynamic> photos = {};
    try {
      final rawPhotos = await rootBundle.loadString('assets/data/photos.json');
      photos = (jsonDecode(rawPhotos) as Map).cast<String, dynamic>();
    } catch (_) {
      // Sin creditos todavia: la app funciona igualmente.
    }

    final animals = list.map((item) {
      final info = photos[item['id']];
      return Animal.fromJson(
        item,
        credit: info is Map
            ? PhotoCredit.fromJson(info.cast<String, dynamic>())
            : null,
      );
    }).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return animals;
  }
}
