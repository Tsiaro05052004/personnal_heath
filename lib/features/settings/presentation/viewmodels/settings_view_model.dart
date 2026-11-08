import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/reminder_preferences.dart';
import '../../../hospitals/di/hospitals_providers.dart';
import '../../../hospitals/domain/entities/location_result.dart';
import '../../../medications/di/medications_providers.dart';
import '../../../medications/domain/repositories/reminder_gateway.dart';

/// Autorisations du téléphone, lues à l'ouverture des Paramètres et au
/// retour des réglages du système.
class PermissionsSnapshot {
  const PermissionsSnapshot({required this.reminders, required this.location});

  final ReminderPermissions reminders;

  /// null = localisation autorisée.
  final LocationProblem? location;
}

final _permissionsProvider = FutureProvider.autoDispose<PermissionsSnapshot>((
  ref,
) async {
  final reminders = await ref.read(reminderGatewayProvider).permissions();
  final location = await ref.read(locationGatewayProvider).status();
  return PermissionsSnapshot(reminders: reminders, location: location);
});

class SettingsUiState {
  const SettingsUiState({required this.reminders, required this.permissions});

  final ReminderPreferences reminders;
  final AsyncValue<PermissionsSnapshot> permissions;
}

final settingsViewModelProvider =
    NotifierProvider.autoDispose<SettingsViewModel, SettingsUiState>(
      SettingsViewModel.new,
    );

/// ViewModel des Paramètres : réglages des rappels et autorisations.
class SettingsViewModel extends Notifier<SettingsUiState> {
  @override
  SettingsUiState build() => SettingsUiState(
    reminders: ref.watch(reminderPreferencesProvider),
    permissions: ref.watch(_permissionsProvider),
  );

  Future<void> setAlarmSound(bool on) async {
    await ref.read(reminderPreferencesProvider.notifier).setAlarmSound(on);
    await _reschedule();
  }

  Future<void> setFollowUpDelay(Duration delay) async {
    await ref
        .read(reminderPreferencesProvider.notifier)
        .setFollowUpDelay(delay);
    await _reschedule();
  }

  /// Notifications + alarmes exactes (fenêtres du système).
  Future<void> requestReminderPermissions() async {
    await ref.read(reminderGatewayProvider).requestPermissions();
    await _reschedule();
    refreshPermissions();
  }

  Future<void> requestLocation() async {
    await ref.read(locationGatewayProvider).requestAndLocate();
    refreshPermissions();
  }

  Future<void> openAppSettings() =>
      ref.read(locationGatewayProvider).openAppSettings();

  Future<void> openLocationSettings() =>
      ref.read(locationGatewayProvider).openLocationSettings();

  /// Relit les autorisations (retour des réglages du téléphone).
  void refreshPermissions() => ref.invalidate(_permissionsProvider);

  /// Les rappels déjà planifiés suivent le nouveau réglage.
  Future<void> _reschedule() async {
    try {
      await ref.read(rescheduleRemindersProvider)();
    } catch (_) {
      // Sans gravité : ils seront recalculés au prochain démarrage.
    }
  }
}
