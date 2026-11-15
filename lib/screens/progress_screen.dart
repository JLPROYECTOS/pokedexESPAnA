import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../state/dex_state.dart';
import '../theme.dart';
import '../widgets/animal_image.dart';
import '../widgets/dex_widgets.dart';
import 'detail_screen.dart';

/// Resumen: total registrado, avance por grupo y ultimos avistamientos.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DexState>();
    final total = state.animals.length;
    final seen = state.seenCount;
    final ratio = total == 0 ? 0.0 : seen / total;
    final recent = state.recentSightings.take(10).toList();

    return DeviceFrame(
      title: 'Progreso',
      subtitle: 'TU CUADERNO DE CAMPO',
      trailing: CounterPill(seen: seen, total: total),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                DexPanel(
                  title: 'Registrados',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$seen',
                            style: dexMono(size: 44, color: DexColors.accent),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 6),
                            child: Text(
                              '/ $total',
                              style: dexMono(size: 18),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${(ratio * 100).round()} %',
                              style: dexMono(size: 18, color: DexColors.text),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DexBar(value: ratio, color: DexColors.accent, height: 14),
                    ],
                  ),
                ),
                DexPanel(
                  title: 'Por grupo',
                  child: Column(
                    children: [
                      for (final c in AnimalCategory.values)
                        _categoryRow(c, state.seenIn(c), state.totalIn(c)),
                    ],
                  ),
                ),
                DexPanel(
                  title: 'Últimos avistamientos',
                  child: recent.isEmpty
                      ? const Text(
                          'Todavía no has registrado ningún animal.',
                          style: TextStyle(color: DexColors.textDim),
                        )
                      : Column(
                          children: [
                            for (final s in recent)
                              _sightingRow(
                                context,
                                state.byId(s.animalId),
                                '${s.dateLabel}'
                                '${s.place != null ? ' · ${s.place}' : ''}',
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _categoryRow(AnimalCategory c, int seen, int total) {
    final color = DexColors.category(c);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(DexColors.categoryIcon(c), size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.label.toUpperCase(),
                  style: dexMono(size: 11, color: DexColors.text),
                ),
              ),
              Text('$seen/$total', style: dexMono(size: 11, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          DexBar(value: total == 0 ? 0 : seen / total, color: color),
        ],
      ),
    );
  }

  Widget _sightingRow(BuildContext context, Animal animal, String detail) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(animalId: animal.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: AnimalImage(animal: animal, seen: true, cacheWidth: 160),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.commonName,
                    style: const TextStyle(
                      color: DexColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DexColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(animal.numberLabel, style: dexMono(size: 11)),
          ],
        ),
      ),
    );
  }
}
