import 'package:flutter/material.dart';

import 'models/animal.dart';

/// Paleta de la interfaz: carcasa roja y pantalla oscura tipo terminal de campo.
class DexColors {
  static const casing = Color(0xFFC62828);
  static const casingDark = Color(0xFF8E1B1B);
  static const screen = Color(0xFF0E1726);
  static const panel = Color(0xFF17243A);
  static const panelLight = Color(0xFF223450);
  static const line = Color(0xFF2E4468);
  static const accent = Color(0xFFFFC94A);
  static const text = Color(0xFFE8EEF7);
  static const textDim = Color(0xFF8FA3BF);
  static const seen = Color(0xFF5BE39B);

  static Color category(AnimalCategory c) {
    switch (c) {
      case AnimalCategory.mamifero:
        return const Color(0xFFE0A15A);
      case AnimalCategory.ave:
        return const Color(0xFF5AB0F0);
      case AnimalCategory.reptil:
        return const Color(0xFF7CCB62);
      case AnimalCategory.anfibio:
        return const Color(0xFFB98BEB);
      case AnimalCategory.pez:
        return const Color(0xFF45CFD6);
    }
  }

  static IconData categoryIcon(AnimalCategory c) {
    switch (c) {
      case AnimalCategory.mamifero:
        return Icons.pets;
      case AnimalCategory.ave:
        return Icons.flutter_dash;
      case AnimalCategory.reptil:
        return Icons.grass;
      case AnimalCategory.anfibio:
        return Icons.water_drop;
      case AnimalCategory.pez:
        return Icons.waves;
    }
  }

  static Color conservation(String code) {
    switch (code) {
      case 'LC':
        return const Color(0xFF5BE39B);
      case 'NT':
        return const Color(0xFFC6E05A);
      case 'VU':
        return const Color(0xFFFFD54A);
      case 'EN':
        return const Color(0xFFFF9A4A);
      case 'CR':
        return const Color(0xFFFF5A5A);
      default:
        return textDim;
    }
  }
}

/// Texto de "lectura de pantalla": monoespaciado y en versalitas.
TextStyle dexMono({
  double size = 12,
  Color color = DexColors.textDim,
  FontWeight weight = FontWeight.w700,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: 1,
  );
}

ThemeData buildDexTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: DexColors.casing,
    brightness: Brightness.dark,
  ).copyWith(
    primary: DexColors.accent,
    onPrimary: Colors.black,
    surface: DexColors.panel,
    onSurface: DexColors.text,
  );

  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: DexColors.casing,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DexColors.panel,
      isDense: true,
      hintStyle: const TextStyle(color: DexColors.textDim),
      border: border(DexColors.line),
      enabledBorder: border(DexColors.line),
      focusedBorder: border(DexColors.accent),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DexColors.casingDark,
      indicatorColor: DexColors.accent,
      height: 66,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Colors.black
              : Colors.white,
        ),
      ),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}
