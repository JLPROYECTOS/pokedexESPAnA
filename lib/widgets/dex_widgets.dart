import 'package:flutter/material.dart';

import '../theme.dart';

/// Marco de la aplicacion: carcasa roja con cabecera y una "pantalla" oscura
/// redondeada donde va el contenido.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DexColors.casing,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      if (leading != null) leading!,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: dexMono(size: 10, color: Colors.white70),
                              ),
                          ],
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: DexColors.screen,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: DexColors.casingDark, width: 4),
                    ),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contador "012/157" de la cabecera.
class CounterPill extends StatelessWidget {
  const CounterPill({super.key, required this.seen, required this.total});

  final int seen;
  final int total;

  @override
  Widget build(BuildContext context) {
    final width = total.toString().length < 3 ? 3 : total.toString().length;
    String pad(int v) => v.toString().padLeft(width, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DexColors.screen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DexColors.casingDark, width: 2),
      ),
      child: Text(
        '${pad(seen)}/${pad(total)}',
        style: dexMono(size: 14, color: DexColors.accent),
      ),
    );
  }
}

/// Panel con titulo, como una seccion de la pantalla del dispositivo.
class DexPanel extends StatelessWidget {
  const DexPanel({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DexColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DexColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: dexMono(size: 11, color: DexColors.accent)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Etiqueta de color (categoria, estado de conservacion...).
class DexTag extends StatelessWidget {
  const DexTag({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: dexMono(size: 11, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boton de filtro seleccionable.
class DexChip extends StatelessWidget {
  const DexChip({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color : DexColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? color : DexColors.line),
          ),
          child: Text(
            label.toUpperCase(),
            style: dexMono(
              size: 11,
              color: selected ? Colors.black : DexColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de progreso con esquinas redondeadas.
class DexBar extends StatelessWidget {
  const DexBar({super.key, required this.value, required this.color, this.height = 10});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        minHeight: height,
        color: color,
        backgroundColor: DexColors.panelLight,
      ),
    );
  }
}
