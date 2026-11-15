import 'package:flutter/material.dart';

import '../models/animal.dart';
import 'animal_image.dart';

/// Miniatura de la cuadricula con su estado (pendiente / registrado).
class AnimalTile extends StatelessWidget {
  const AnimalTile({
    super.key,
    required this.animal,
    required this.seen,
    required this.onTap,
  });

  final Animal animal;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'animal-${animal.id}',
                    child: AnimalImage(animal: animal, seen: seen),
                  ),
                  Positioned(
                    left: 6,
                    top: 4,
                    child: Text(
                      animal.numberLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 3, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                  if (seen) const Center(child: _SeenStamp()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                animal.commonName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: seen ? FontWeight.bold : FontWeight.normal,
                  color: seen ? null : theme.disabledColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeenStamp extends StatelessWidget {
  const _SeenStamp();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2E7D32);
    return Transform.rotate(
      angle: -0.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'VISTO',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
