import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/dex_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DexState()..load(),
      child: const IbericoDexApp(),
    ),
  );
}

class IbericoDexApp extends StatelessWidget {
  const IbericoDexApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFC62828);
    return MaterialApp(
      title: 'IbéricoDex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        appBarTheme: const AppBarTheme(
          backgroundColor: seed,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
