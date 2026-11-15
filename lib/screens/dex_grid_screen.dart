import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../services/identifier_service.dart';
import '../state/dex_state.dart';
import '../widgets/animal_tile.dart';
import 'detail_screen.dart';

/// Pantalla principal: buscador, filtros por categoria y cuadricula.
class DexGridScreen extends StatefulWidget {
  const DexGridScreen({super.key});

  @override
  State<DexGridScreen> createState() => _DexGridScreenState();
}

class _DexGridScreenState extends State<DexGridScreen> {
  String _query = '';
  AnimalCategory? _category;

  List<Animal> _filter(List<Animal> animals) {
    final q = IdentifierService.normalize(_query.trim());
    return animals.where((a) {
      if (_category != null && a.category != _category) return false;
      if (q.isEmpty) return true;
      return IdentifierService.normalize(a.commonName).contains(q) ||
          IdentifierService.normalize(a.scientificName).contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DexState>();
    final visible = _filter(state.animals);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IbéricoDex'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${state.seenCount} / ${state.animals.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nombre',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _chip('Todos', null),
                      for (final c in AnimalCategory.values) _chip(c.label, c),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(child: Text('Sin resultados'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 140,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: visible.length,
                          itemBuilder: (context, i) {
                            final animal = visible[i];
                            return AnimalTile(
                              animal: animal,
                              seen: state.isSeen(animal.id),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailScreen(animalId: animal.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, AnimalCategory? category) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _category == category,
        onSelected: (_) => setState(() => _category = category),
      ),
    );
  }
}
