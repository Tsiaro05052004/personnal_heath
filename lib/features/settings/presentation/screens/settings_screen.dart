import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/notifications/reminder_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../hospitals/domain/entities/location_result.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/account_section.dart';

/// Paramètres : rappels, autorisations du téléphone, eau, compte.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Au retour des réglages du téléphone, on relit les autorisations.
  late final _lifecycle = AppLifecycleListener(
    onResume: () =>
        ref.read(settingsViewModelProvider.notifier).refreshPermissions(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsViewModelProvider);
    final vm = ref.read(settingsViewModelProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // ------------------------------------------------ Rappels
          const FormQuestion('Rappels de médicaments'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SwitchListTile(
              value: state.reminders.alarmSound,
              onChanged: vm.setAlarmSound,
              title: Text('Alarme sonore', style: text.titleMedium),
              subtitle: const Text(
                'Sonnerie de réveil jusqu’à ce que vous répondiez (5 min au '
                'plus). Sinon, un simple son de notification.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Deuxième rappel', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Si la prise n’est pas confirmée, un nouveau rappel arrive après :',
            style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (i, delay)
                  in ReminderPreferences.followUpChoices.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: ChoiceButton(
                    label: delay.inMinutes < 60
                        ? '${delay.inMinutes} min'
                        : '${delay.inHours} h',
                    selected: state.reminders.followUpDelay == delay,
                    onTap: () => vm.setFollowUpDelay(delay),
                  ),
                ),
              ],
            ],
          ),

          // ------------------------------------------- Autorisations
          const FormQuestion('Autorisations du téléphone'),
          switch (state.permissions) {
            AsyncData(value: final p) => _Permissions(
              snapshot: p,
              onRequestReminders: vm.requestReminderPermissions,
              onRequestLocation: vm.requestLocation,
              onOpenAppSettings: vm.openAppSettings,
              onOpenLocationSettings: vm.openLocationSettings,
            ),
            AsyncError() => const AppCard(
              child: Text('Impossible de lire les autorisations.'),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          },

          // ------------------------------------------------------ Eau
          const FormQuestion('Eau'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              minTileHeight: 64,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.water_drop, color: AppColors.water),
              title: Text("Mon objectif d'eau", style: text.bodyLarge),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.waterGoal),
            ),
          ),

          // ---------------------------------------------------- Compte
          const FormQuestion('Compte'),
          AccountSection(state: state, vm: vm),

          // ------------------------------------------------- À propos
          const FormQuestion('À propos'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ma Santé', style: text.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Cette application vous aide à vous souvenir de vos '
                  'médicaments et de boire régulièrement. Elle ne remplace '
                  'pas l’avis d’un médecin ou d’un pharmacien.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Permissions extends StatelessWidget {
  const _Permissions({
    required this.snapshot,
    required this.onRequestReminders,
    required this.onRequestLocation,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
  });

  final PermissionsSnapshot snapshot;
  final VoidCallback onRequestReminders;
  final VoidCallback onRequestLocation;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final reminders = snapshot.reminders;
    if (!reminders.supported) {
      return const AppCard(
        child: Text(
          'Les rappels ne fonctionnent que sur un téléphone Android ou '
          'iPhone.',
        ),
      );
    }
    final location = snapshot.location;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PermissionRow(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            granted: reminders.notifications,
            missing: 'Refusées : aucun rappel ne s’affichera.',
            action: ('Autoriser', onRequestReminders),
          ),
          const Divider(),
          _PermissionRow(
            icon: Icons.alarm,
            title: 'Rappels à l’heure exacte',
            granted: reminders.exactAlarms,
            missing: 'Non autorisés : les rappels peuvent arriver en retard.',
            action: ('Autoriser', onRequestReminders),
          ),
          const Divider(),
          _PermissionRow(
            icon: Icons.my_location,
            title: 'Localisation',
            granted:
                location == null || location == LocationProblem.unavailable,
            missing: switch (location) {
              LocationProblem.serviceDisabled =>
                'La localisation du téléphone est désactivée.',
              LocationProblem.permissionDeniedForever =>
                'Refusée : à autoriser dans les réglages de l’application.',
              _ => 'Pas encore autorisée (carte des hôpitaux).',
            },
            action: switch (location) {
              LocationProblem.serviceDisabled => (
                'Activer',
                onOpenLocationSettings,
              ),
              LocationProblem.permissionDeniedForever => (
                'Ouvrir les réglages',
                onOpenAppSettings,
              ),
              _ => ('Autoriser', onRequestLocation),
            },
          ),
          const Divider(),
          _BackgroundHelp(onOpenAppSettings: onOpenAppSettings),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.granted,
    required this.missing,
    required this.action,
  });

  final IconData icon;
  final String title;
  final bool granted;
  final String missing;
  final (String, VoidCallback) action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (label, onPressed) = action;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: text.titleMedium)),
              Icon(
                granted ? Icons.check_circle : Icons.error_outline,
                color: granted ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            granted ? 'Autorisé' : missing,
            style: text.bodyMedium?.copyWith(
              color: granted ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!granted) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onPressed, child: Text(label)),
          ],
        ],
      ),
    );
  }
}

/// Les surcouches de certaines marques bloquent les applis en arrière-plan :
/// l'appli ne peut pas le savoir, elle explique quoi faire.
class _BackgroundHelp extends StatelessWidget {
  const _BackgroundHelp({required this.onOpenAppSettings});

  final VoidCallback onOpenAppSettings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_alert_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Fonctionnement en arrière-plan',
                  style: text.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sur certains téléphones (Realme, Oppo, Xiaomi…), l’économie de '
            'batterie peut bloquer les rappels. Dans les réglages de '
            'l’application, ouvrez « Batterie » et autorisez l’activité en '
            'arrière-plan.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onOpenAppSettings,
            child: const Text('Ouvrir les réglages'),
          ),
        ],
      ),
    );
  }
}
