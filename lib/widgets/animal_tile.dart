import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../theme.dart';
import 'animal_image.dart';

/// Celda de la cuadricula con su estado (pendiente / registrado).
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
    final color = DexColors.category(animal.category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: DexColors.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seen ? color : DexColors.line,
            width: seen ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'animal-${animal.id}',
                    child: AnimalImage(
                      animal: animal,
                      seen: seen,
                      cacheWidth: 320,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xCC0E1726),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        animal.numberLabel,
                        style: dexMono(
                          size: 10,
                          color: seen ? DexColors.accent : DexColors.textDim,
                        ),
                      ),
                    ),
                  ),
                  if (seen)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: DexColors.seen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(height: 3, color: seen ? color : DexColors.line),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Text(
                animal.commonName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: seen ? FontWeight.w800 : FontWeight.w500,
                  color: seen ? DexColors.text : DexColors.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
