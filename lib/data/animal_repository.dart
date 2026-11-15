import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/animal.dart';

/// Fuente de datos del catalogo. Hoy lee un JSON empaquetado en la app;
/// se puede sustituir por una base de datos local o una API sin tocar la UI.
class AnimalRepository {
  Future<List<Animal>> loadAll() async {
    final raw = await rootBundle.loadString('assets/data/animals.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final animals = list.map(Animal.fromJson).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return animals;
  }
}
