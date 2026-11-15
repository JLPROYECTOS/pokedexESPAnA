import 'package:flutter/material.dart';

import '../models/animal.dart';

/// Foto del animal. En gris y atenuada si aun no se ha registrado.
/// Si falta el archivo de imagen muestra un marcador, asi la app
/// funciona antes de anadir las fotos.
class AnimalImage extends StatelessWidget {
  const AnimalImage({super.key, required this.animal, required this.seen});

  final Animal animal;
  final bool seen;

  static const _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = Image.asset(
      animal.image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: scheme.primaryContainer,
        alignment: Alignment.center,
        child: Icon(Icons.pets, size: 40, color: scheme.onPrimaryContainer),
      ),
    );
    if (seen) return image;
    return ColorFiltered(
      colorFilter: _greyscale,
      child: Opacity(opacity: 0.55, child: image),
    );
  }
}
