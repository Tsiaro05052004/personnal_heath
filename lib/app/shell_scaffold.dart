import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/pill_icon.dart';

/// Squelette commun aux 5 onglets : contenu + barre de navigation du bas.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Accueil',
    ),
    NavigationDestination(icon: PillIcon(), label: 'Médicaments'),
    NavigationDestination(
      icon: Icon(Icons.water_drop_outlined),
      selectedIcon: Icon(Icons.water_drop),
      label: 'Eau',
    ),
    NavigationDestination(
      icon: Icon(Icons.add_location_alt_outlined),
      selectedIcon: Icon(Icons.add_location_alt),
      label: 'Hôpitaux',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Historique',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        destinations: _destinations,
        // Toucher l'onglet actif revient à sa page de départ.
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}
