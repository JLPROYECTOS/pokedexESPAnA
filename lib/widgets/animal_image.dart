import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../theme.dart';

/// Foto del animal. En gris y atenuada si aun no se ha registrado.
/// Si falta el archivo de imagen muestra un icono de su grupo.
class AnimalImage extends StatelessWidget {
  const AnimalImage({
    super.key,
    required this.animal,
    required this.seen,
    this.cacheWidth,
  });

  final Animal animal;
  final bool seen;

  /// Ancho de decodificacion para miniaturas (ahorra memoria en la cuadricula).
  final int? cacheWidth;

  static const _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final color = DexColors.category(animal.category);
    final image = Image.asset(
      animal.image,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => Container(
        color: DexColors.panelLight,
        alignment: Alignment.center,
        child: Icon(
          DexColors.categoryIcon(animal.category),
          size: 40,
          color: color,
        ),
      ),
    );
    if (seen) return image;
    return ColorFiltered(
      colorFilter: _greyscale,
      child: Opacity(opacity: 0.45, child: image),
    );
  }
}
