import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/dex_state.dart';
import 'theme.dart';

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
    return MaterialApp(
      title: 'IbéricoDex',
      debugShowCheckedModeBanner: false,
      theme: buildDexTheme(),
      home: const HomeScreen(),
    );
  }
}
