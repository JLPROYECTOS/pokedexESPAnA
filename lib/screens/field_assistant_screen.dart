import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/identifier_service.dart';
import '../state/dex_state.dart';
import '../theme.dart';
import '../widgets/animal_image.dart';
import '../widgets/dex_widgets.dart';
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

    return DeviceFrame(
      title: 'Escáner de campo',
      subtitle: 'IDENTIFICACIÓN POR DESCRIPCIÓN',
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          DexPanel(
            title: 'Describe el animal',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tamaño, colores, marcas llamativas y dónde estaba.',
                  style: TextStyle(color: DexColors.textDim),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  minLines: 3,
                  maxLines: 5,
                  style: const TextStyle(color: DexColors.text),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    fillColor: DexColors.screen,
                    hintText:
                        'Ej.: es un pájaro mediano, negro con el pico rojo '
                        'y vive cerca de un río',
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _identify,
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('ANALIZAR'),
                  ),
                ),
              ],
            ),
          ),
          if (results != null && results.isEmpty)
            DexPanel(
              title: 'Sin coincidencias',
              child: const Text(
                'Prueba a añadir colores, tamaño o el tipo de animal.',
                style: TextStyle(color: DexColors.text),
              ),
            ),
          if (results != null && results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
              child: Text(
                '${results.length} CANDIDATOS',
                style: dexMono(size: 10),
              ),
            ),
          if (results != null)
            for (var i = 0; i < results.length; i++)
              _suggestionCard(context, state, results[i], i + 1),
        ],
      ),
    );
  }

  Widget _suggestionCard(
    BuildContext context,
    DexState state,
    Suggestion s,
    int rank,
  ) {
    final seen = state.isSeen(s.animal.id);
    final percent = (s.score * 100).round();
    final color = DexColors.category(s.animal.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DexColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rank == 1 ? DexColors.accent : DexColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: AnimalImage(
                    animal: s.animal,
                    seen: true,
                    cacheWidth: 220,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.animal.numberLabel} · ${s.animal.category.singular.toUpperCase()}',
                      style: dexMono(size: 10, color: color),
                    ),
                    Text(
                      s.animal.commonName,
                      style: const TextStyle(
                        color: DexColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      s.animal.scientificName,
                      style: const TextStyle(
                        color: DexColors.textDim,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DexBar(value: s.score, color: DexColors.accent),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percent %',
                          style: dexMono(size: 12, color: DexColors.accent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Encaja en: ${s.matched.join(', ')}',
            style: const TextStyle(color: DexColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(animalId: s.animal.id),
                    ),
                  ),
                  child: const Text('VER FICHA'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      seen ? null : () => showRegisterDialog(context, s.animal),
                  icon: Icon(seen ? Icons.verified : Icons.check, size: 18),
                  label: Text(seen ? 'REGISTRADO' : 'ES ESTE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
