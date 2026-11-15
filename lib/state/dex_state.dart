import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/animal_repository.dart';
import '../models/animal.dart';
import '../models/sighting.dart';

/// Estado global: catalogo + avistamientos del usuario (persistidos en local).
class DexState extends ChangeNotifier {
  DexState({AnimalRepository? repository})
      : _repository = repository ?? AnimalRepository();

  static const _prefsKey = 'sightings_v1';

  final AnimalRepository _repository;
  final Map<String, Sighting> _sightings = {};

  List<Animal> animals = const [];
  bool loading = true;

  int get seenCount => animals.where((a) => isSeen(a.id)).length;

  bool isSeen(String animalId) => _sightings.containsKey(animalId);

  Sighting? sightingOf(String animalId) => _sightings[animalId];

  Animal byId(String id) => animals.firstWhere((a) => a.id == id);

  int totalIn(AnimalCategory c) => animals.where((a) => a.category == c).length;

  int seenIn(AnimalCategory c) =>
      animals.where((a) => a.category == c && isSeen(a.id)).length;

  /// Avistamientos de animales del catalogo, del mas reciente al mas antiguo.
  List<Sighting> get recentSightings {
    final ids = animals.map((a) => a.id).toSet();
    final list = _sightings.values.where((s) => ids.contains(s.animalId)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> load() async {
    animals = await _repository.loadAll();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final item in list) {
        final sighting = Sighting.fromJson(item);
        _sightings[sighting.animalId] = sighting;
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> register(String animalId, {String? place}) async {
    final cleanPlace = place?.trim();
    _sightings[animalId] = Sighting(
      animalId: animalId,
      date: DateTime.now(),
      place: (cleanPlace == null || cleanPlace.isEmpty) ? null : cleanPlace,
    );
    notifyListeners();
    await _save();
  }

  Future<void> unregister(String animalId) async {
    _sightings.remove(animalId);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _sightings.values.map((s) => s.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }
}
