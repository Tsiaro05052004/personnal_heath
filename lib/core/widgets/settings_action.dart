import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

/// Bouton ⚙ de la barre du haut, qui ouvre les Paramètres.
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.settings, size: 30),
    tooltip: 'Paramètres',
    onPressed: () => context.push(AppRoutes.settings),
  );
}
