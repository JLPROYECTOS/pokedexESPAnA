import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/animal.dart';
import '../services/identifier_service.dart';

/// Fuente de datos del catalogo: assets/data/catalog.json, generado por
/// scripts/build_catalog.py. Devuelve las especies en orden alfabetico y
/// numeradas segun ese orden.
class AnimalRepository {
  Future<List<Animal>> loadAll() async {
    final raw = await rootBundle.loadString('assets/data/catalog.json');
    final decoded = jsonDecode(raw);
    final list = ((decoded is Map ? decoded['animals'] : decoded) as List)
        .cast<Map<String, dynamic>>();

    final sorted = [...list]..sort(
        (a, b) => IdentifierService.normalize(a['commonName'] as String)
            .compareTo(IdentifierService.normalize(b['commonName'] as String)),
      );

    return [
      for (var i = 0; i < sorted.length; i++)
        Animal.fromJson(sorted[i], number: i + 1),
    ];
  }
}
