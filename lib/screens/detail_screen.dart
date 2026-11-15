import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dex_state.dart';
import '../widgets/animal_image.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${animal.numberLabel}  ${animal.commonName}')),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Hero(
              tag: 'animal-${animal.id}',
              child: AnimalImage(animal: animal, seen: seen),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animal.commonName, style: theme.textTheme.headlineSmall),
                Text(
                  animal.scientificName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                Card(
                  color: seen
                      ? const Color(0xFFE8F5E9)
                      : theme.colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    leading: Icon(
                      seen ? Icons.verified : Icons.help_outline,
                      color: seen ? const Color(0xFF2E7D32) : null,
                    ),
                    title: Text(seen ? 'Registrado' : 'Aún no lo has visto'),
                    subtitle: seen
                        ? Text(
                            '${sighting.dateLabel}'
                            '${sighting.place != null ? ' · ${sighting.place}' : ''}',
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                _row('Categoría', animal.category.label),
                _row('Familia', animal.family),
                _row('Hábitat', animal.habitat),
                _row('Conservación', animal.conservationLabel),
                const SizedBox(height: 12),
                Text('Descripción', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(animal.description),
                const SizedBox(height: 12),
                Text('Curiosidades', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                for (final fact in animal.facts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $fact'),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: seen
                      ? OutlinedButton.icon(
                          onPressed: () => state.unregister(animal.id),
                          icon: const Icon(Icons.undo),
                          label: const Text('Quitar registro'),
                        )
                      : FilledButton.icon(
                          onPressed: () => showRegisterDialog(context, animal),
                          icon: const Icon(Icons.check),
                          label: const Text('¡Lo he visto!'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
