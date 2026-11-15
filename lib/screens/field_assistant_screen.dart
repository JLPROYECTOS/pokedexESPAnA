import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/identifier_service.dart';
import '../state/dex_state.dart';
import '../widgets/animal_image.dart';
import '../widgets/register_dialog.dart';
import 'detail_screen.dart';

/// Asistente de campo: el usuario describe lo que ha visto y recibe
/// candidatos ordenados por coincidencia, con registro directo.
class FieldAssistantScreen extends StatefulWidget {
  const FieldAssistantScreen({super.key});

  @override
  State<FieldAssistantScreen> createState() => _FieldAssistantScreenState();
}

class _FieldAssistantScreenState extends State<FieldAssistantScreen> {
  final _controller = TextEditingController();
  final _service = IdentifierService();
  List<Suggestion>? _results;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _identify() {
    FocusScope.of(context).unfocus();
    final animals = context.read<DexState>().animals;
    setState(() => _results = _service.identify(_controller.text, animals));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DexState>();
    final results = _results;

    return Scaffold(
      appBar: AppBar(title: const Text('Asistente de campo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Describe el animal que acabas de ver: tamaño, colores, '
            'marcas llamativas y dónde estaba.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  'Ej.: es un pájaro mediano, negro con el pico rojo y '
                  'vive cerca de un río',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _identify,
            icon: const Icon(Icons.travel_explore),
            label: const Text('Identificar'),
          ),
          const SizedBox(height: 16),
          if (results != null && results.isEmpty)
            const Text(
              'No encuentro coincidencias. Prueba a añadir colores, '
              'tamaño o el tipo de animal.',
            ),
          if (results != null)
            for (final s in results) _suggestionCard(context, state, s),
        ],
      ),
    );
  }

  Widget _suggestionCard(BuildContext context, DexState state, Suggestion s) {
    final seen = state.isSeen(s.animal.id);
    final percent = (s.score * 100).round();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: AnimalImage(animal: s.animal, seen: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.animal.commonName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        s.animal.scientificName,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: s.score.clamp(0, 1)),
                      const SizedBox(height: 2),
                      Text('Coincidencia: $percent %'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Encaja en: ${s.matched.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(animalId: s.animal.id),
                    ),
                  ),
                  child: const Text('Ver ficha'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: seen
                      ? null
                      : () => showRegisterDialog(context, s.animal),
                  icon: Icon(seen ? Icons.verified : Icons.check),
                  label: Text(seen ? 'Ya registrado' : 'Es este, registrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
