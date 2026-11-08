import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/pill_icon.dart';

/// Squelette commun aux 5 onglets : contenu + barre de navigation du bas.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: shell.currentIndex,
        // Toucher l'onglet actif revient à sa page de départ.
        onSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}

/// Un onglet de la barre du bas.
class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

/// Barre du bas des maquettes. Faite sur mesure plutôt que NavigationBar :
/// sur un téléphone de 360 dp (le Realme de test), « Médicaments » passait
/// à la ligne, et NavigationBar ne permet pas de l'empêcher.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const tabs = [
    _Tab('Accueil', Icon(Icons.home_outlined), Icon(Icons.home)),
    _Tab('Médicaments', PillIcon(), PillIcon()),
    _Tab('Eau', Icon(Icons.water_drop_outlined), Icon(Icons.water_drop)),
    _Tab(
      'Hôpitaux',
      Icon(Icons.add_location_alt_outlined),
      Icon(Icons.add_location_alt),
    ),
    _Tab(
      'Historique',
      Icon(Icons.calendar_today_outlined),
      Icon(Icons.calendar_today),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                for (final (i, tab) in tabs.indexed)
                  Expanded(
                    child: _TabButton(
                      tab: tab,
                      index: i,
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
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

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${tab.label}, onglet ${index + 1} sur ${AppNavigationBar.tabs.length}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: IconTheme(
                  data: IconThemeData(color: color, size: 28),
                  child: selected ? tab.selectedIcon : tab.icon,
                ),
              ),
              const SizedBox(height: 4),
              // Une seule ligne, quitte à rétrécir un peu le mot.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
