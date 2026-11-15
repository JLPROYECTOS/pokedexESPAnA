import 'package:flutter/material.dart';

import '../theme.dart';
import 'dex_grid_screen.dart';
import 'field_assistant_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DexColors.casing,
      body: IndexedStack(
        index: _index,
        children: const [
          DexGridScreen(),
          FieldAssistantScreen(),
          ProgressScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.apps), label: 'ÍNDICE'),
          NavigationDestination(
            icon: Icon(Icons.center_focus_strong),
            label: 'ESCÁNER',
          ),
          NavigationDestination(icon: Icon(Icons.insights), label: 'PROGRESO'),
        ],
      ),
    );
  }
}
