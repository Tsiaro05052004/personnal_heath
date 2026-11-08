import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';

/// Bouton rond « profil » (en haut de l'accueil) : ouvre les Paramètres.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    icon: const Icon(Icons.person_outline, size: 30),
    tooltip: 'Profil et paramètres',
    style: IconButton.styleFrom(
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.outline),
      minimumSize: const Size(56, 56),
    ),
    onPressed: () => context.push(AppRoutes.settings),
  );
}
