import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../state/dex_state.dart';

/// Pide el lugar (opcional) y registra el avistamiento con la fecha de hoy.
Future<void> showRegisterDialog(BuildContext context, Animal animal) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Registrar ${animal.commonName}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: '¿Dónde lo has visto? (opcional)',
          hintText: 'Ej.: Sierra de Andújar',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Registrar'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<DexState>().register(animal.id, place: controller.text);
  }
}
