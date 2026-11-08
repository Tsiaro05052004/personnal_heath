import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/preferences_store.dart';

/// Réglages des rappels de médicaments (écran Paramètres).
class ReminderPreferences {
  const ReminderPreferences({
    this.alarmSound = true,
    this.followUpDelay = const Duration(minutes: 30),
  });

  /// Sonnerie de réveil répétée plutôt qu'un simple son de notification.
  /// Activée par défaut (choix de l'utilisateur, 2026-11-08).
  final bool alarmSound;

  /// Délai du 2e rappel si la prise n'est pas confirmée.
  final Duration followUpDelay;

  static const followUpChoices = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
  ];
}

final reminderPreferencesProvider =
    NotifierProvider<ReminderPreferencesNotifier, ReminderPreferences>(
      ReminderPreferencesNotifier.new,
    );

class ReminderPreferencesNotifier extends Notifier<ReminderPreferences> {
  static const _alarmKey = 'rappels.alarme_sonore';
  static const _followUpKey = 'rappels.delai_2e_rappel_min';

  @override
  ReminderPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    const defaults = ReminderPreferences();
    final minutes = prefs.getInt(_followUpKey);
    return ReminderPreferences(
      alarmSound: prefs.getBool(_alarmKey) ?? defaults.alarmSound,
      followUpDelay: minutes == null
          ? defaults.followUpDelay
          : Duration(minutes: minutes),
    );
  }

  Future<void> setAlarmSound(bool on) async {
    await ref.read(sharedPreferencesProvider).setBool(_alarmKey, on);
    state = ReminderPreferences(
      alarmSound: on,
      followUpDelay: state.followUpDelay,
    );
  }

  Future<void> setFollowUpDelay(Duration delay) async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_followUpKey, delay.inMinutes);
    state = ReminderPreferences(
      alarmSound: state.alarmSound,
      followUpDelay: delay,
    );
  }
}
