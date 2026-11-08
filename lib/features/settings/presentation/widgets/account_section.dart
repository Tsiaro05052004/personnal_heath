import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';
import '../viewmodels/settings_view_model.dart';

/// Rubrique « Compte » des Paramètres.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key, required this.state, required this.vm});

  final SettingsUiState state;
  final SettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = state.user;
    if (!state.accountsEnabled || user == null) {
      return const AppCard(
        child: Text(
          'Cette version de l’application n’est pas reliée au serveur : vos '
          'données restent sur ce téléphone.',
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user.displayName?.isNotEmpty ?? false)
            Text(user.displayName!, style: text.titleMedium),
          Text(
            user.email,
            style: text.bodyLarge?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.cloud_done_outlined,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vos données sont sauvegardées dès que le téléphone est '
                  'connecté à Internet.',
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => _delete(context),
            child: const Text('Supprimer mon compte et mes données'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Se déconnecter ?',
      body:
          'Vos données sont sauvegardées sur votre compte. Elles seront '
          'effacées de ce téléphone et les rappels s’arrêteront jusqu’à votre '
          'prochaine connexion.',
      action: 'Se déconnecter',
    );
    if (!ok) return;
    final result = await vm.signOut();
    if (result == SignOutResult.unsavedData && context.mounted) {
      final force = await _confirm(
        context,
        title: 'Données non sauvegardées',
        body:
            'Le téléphone n’est pas connecté à Internet : vos dernières '
            'modifications ne sont pas encore sauvegardées et seront '
            'perdues. Se déconnecter quand même ?',
        action: 'Se déconnecter quand même',
        danger: true,
      );
      if (force) await vm.signOut(force: true);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Supprimer votre compte ?',
      body:
          'Votre compte et TOUTES vos données (médicaments, prises, eau) '
          'seront supprimés définitivement, sur ce téléphone et sur le '
          'serveur. Cette action ne peut pas être annulée.',
      action: 'Supprimer définitivement',
      danger: true,
    );
    if (!ok) return;
    final deleted = await vm.deleteAccount();
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La suppression a échoué. Vérifiez votre connexion Internet et '
            'réessayez.',
          ),
        ),
      );
    }
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    bool danger = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: danger
                  ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}
