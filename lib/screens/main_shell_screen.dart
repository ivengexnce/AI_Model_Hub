import 'package:flutter/material.dart';
import 'decision_engine_screen.dart';
import 'model_list_screen.dart';
import 'saved_decisions_screen.dart';

/// Main Shell Screen implementing the 3-Tab Clean Navigation (BroML Blueprint 1.0)
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DecisionEngineScreen(),
      const ModelListScreen(),
      SavedDecisionsScreen(
        onStartDecision: () => setState(() => _currentIndex = 0),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology_rounded, color: Colors.cyanAccent),
            label: 'Decision Engine',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: Colors.cyanAccent),
            label: 'Model Catalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_edu_outlined),
            selectedIcon: Icon(Icons.history_edu_rounded, color: Colors.cyanAccent),
            label: 'Saved Decisions',
          ),
        ],
      ),
    );
  }
}

