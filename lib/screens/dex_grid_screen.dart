import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../services/identifier_service.dart';
import '../state/dex_state.dart';
import '../theme.dart';
import '../widgets/animal_tile.dart';
import '../widgets/dex_widgets.dart';
import 'detail_screen.dart';

enum SeenFilter { all, seen, pending }

/// Pantalla principal: buscador, filtros y cuadricula numerada.
class DexGridScreen extends StatefulWidget {
  const DexGridScreen({super.key});

  @override
  State<DexGridScreen> createState() => _DexGridScreenState();
}

class _DexGridScreenState extends State<DexGridScreen> {
  String _query = '';
  AnimalCategory? _category;
  SeenFilter _seenFilter = SeenFilter.all;

  List<Animal> _filter(DexState state) {
    final q = IdentifierService.normalize(_query.trim());
    return state.animals.where((a) {
      if (_category != null && a.category != _category) return false;
      final seen = state.isSeen(a.id);
      if (_seenFilter == SeenFilter.seen && !seen) return false;
      if (_seenFilter == SeenFilter.pending && seen) return false;
      if (q.isEmpty) return true;
      return IdentifierService.normalize(a.commonName).contains(q) ||
          IdentifierService.normalize(a.scientificName).contains(q) ||
          a.number.toString() == q;
    }).toList();
  }

  String get _seenFilterLabel {
    switch (_seenFilter) {
      case SeenFilter.all:
        return 'TODOS';
      case SeenFilter.seen:
        return 'VISTOS';
      case SeenFilter.pending:
        return 'PENDIENTES';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DexState>();
    final visible = _filter(state);

    return DeviceFrame(
      title: 'IbéricoDex',
      subtitle: 'FAUNA DE LA PENÍNSULA IBÉRICA',
      trailing: CounterPill(seen: state.seenCount, total: state.animals.length),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(color: DexColors.text),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              color: DexColors.textDim,
                            ),
                            hintText: 'Buscar por nombre o número',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<SeenFilter>(
                        tooltip: 'Filtrar por estado',
                        initialValue: _seenFilter,
                        onSelected: (v) => setState(() => _seenFilter = v),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: SeenFilter.all,
                            child: Text('Todos'),
                          ),
                          PopupMenuItem(
                            value: SeenFilter.seen,
                            child: Text('Solo vistos'),
                          ),
                          PopupMenuItem(
                            value: SeenFilter.pending,
                            child: Text('Solo pendientes'),
                          ),
                        ],
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: _seenFilter == SeenFilter.all
                                ? DexColors.panel
                                : DexColors.accent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: DexColors.line),
                          ),
                          child: Icon(
                            Icons.tune,
                            color: _seenFilter == SeenFilter.all
                                ? DexColors.text
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      DexChip(
                        label: 'Todos',
                        color: DexColors.accent,
                        selected: _category == null,
                        onTap: () => setState(() => _category = null),
                      ),
                      for (final c in AnimalCategory.values)
                        DexChip(
                          label: c.label,
                          color: DexColors.category(c),
                          selected: _category == c,
                          onTap: () => setState(() => _category = c),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
                  child: Text(
                    '${visible.length} ENTRADAS · $_seenFilterLabel',
                    style: dexMono(size: 10),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            'SIN RESULTADOS',
                            style: dexMono(size: 13),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 130,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.8,
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
}
