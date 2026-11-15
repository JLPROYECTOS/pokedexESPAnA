import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dex_state.dart';
import '../theme.dart';
import '../widgets/animal_image.dart';
import '../widgets/dex_widgets.dart';
import '../widgets/register_dialog.dart';

/// Ficha completa del animal y datos del avistamiento del usuario.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.animalId});

  final String animalId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DexState>();
    final animal = state.byId(animalId);
    final sighting = state.sightingOf(animalId);
    final seen = sighting != null;
    final catColor = DexColors.category(animal.category);
    final credit = animal.credit;

    return Scaffold(
      backgroundColor: DexColors.casing,
      body: DeviceFrame(
        title: 'Entrada ${animal.numberLabel}',
        subtitle: animal.category.label.toUpperCase(),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Volver',
        ),
        trailing: Icon(
          seen ? Icons.verified : Icons.radio_button_unchecked,
          color: seen ? DexColors.seen : Colors.white54,
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'animal-${animal.id}',
                    child: AnimalImage(animal: animal, seen: seen),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 30, 14, 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x000E1726), Color(0xF20E1726)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            animal.commonName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            animal.scientificName,
                            style: const TextStyle(
                              color: DexColors.textDim,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 4, color: catColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DexTag(
                        label: animal.category.singular,
                        color: catColor,
                        icon: DexColors.categoryIcon(animal.category),
                      ),
                      DexTag(
                        label: animal.conservationName,
                        color: DexColors.conservation(animal.conservation),
                        icon: Icons.shield_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DexPanel(
                    title: 'Registro',
                    child: Row(
                      children: [
                        Icon(
                          seen ? Icons.verified : Icons.help_outline,
                          color: seen ? DexColors.seen : DexColors.textDim,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            seen
                                ? 'Visto el ${sighting.dateLabel}'
                                    '${sighting.place != null ? '\n${sighting.place}' : ''}'
                                : 'Aún no lo has visto',
                            style: TextStyle(
                              color: seen ? DexColors.text : DexColors.textDim,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DexPanel(
                    title: 'Datos',
                    child: Column(
                      children: [
                        _row('Familia', animal.family),
                        _row('Hábitat', animal.habitat),
                        _row('Estado', animal.conservationLabel),
                      ],
                    ),
                  ),
                  DexPanel(
                    title: 'Descripción',
                    child: Text(
                      animal.description,
                      style: const TextStyle(
                        color: DexColors.text,
                        height: 1.45,
                      ),
                    ),
                  ),
                  DexPanel(
                    title: 'Curiosidades',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final fact in animal.facts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('▸ ', style: TextStyle(color: catColor)),
                                Expanded(
                                  child: Text(
                                    fact,
                                    style: const TextStyle(
                                      color: DexColors.text,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: seen
                        ? OutlinedButton.icon(
                            onPressed: () => state.unregister(animal.id),
                            icon: const Icon(Icons.undo),
                            label: const Text('QUITAR REGISTRO'),
                          )
                        : FilledButton.icon(
                            onPressed: () =>
                                showRegisterDialog(context, animal),
                            icon: const Icon(Icons.check),
                            label: const Text('¡LO HE VISTO!'),
                          ),
                  ),
                  if (credit != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Foto: ${credit.author} · ${credit.license} · '
                      'Wikimedia Commons',
                      style: const TextStyle(
                        color: DexColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(label.toUpperCase(), style: dexMono(size: 10)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: DexColors.text)),
          ),
        ],
      ),
    );
  }
}
