import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/hydration_providers.dart';
import '../../domain/entities/water_settings.dart';
import '../../domain/services/water_rules.dart';

/// État du formulaire « Mon objectif d'eau ».
class WaterGoalUiState {
  const WaterGoalUiState({
    required this.settings,
    required this.isFirstTime,
    this.errors = const {},
    this.saving = false,
  });

  final WaterSettings settings;

  /// Premier paramétrage (aucun objectif enregistré).
  final bool isFirstTime;
  final Set<WaterSettingsError> errors;
  final bool saving;

  WaterGoalUiState copyWith({
    WaterSettings? settings,
    Set<WaterSettingsError>? errors,
    bool? saving,
  }) => WaterGoalUiState(
    settings: settings ?? this.settings,
    isFirstTime: isFirstTime,
    errors: errors ?? this.errors,
    saving: saving ?? this.saving,
  );
}

final waterGoalViewModelProvider =
    AsyncNotifierProvider.autoDispose<WaterGoalViewModel, WaterGoalUiState>(
      WaterGoalViewModel.new,
    );

class WaterGoalViewModel extends AsyncNotifier<WaterGoalUiState> {
  @override
  Future<WaterGoalUiState> build() async {
    final saved = await ref.read(getWaterSettingsProvider)();
    return WaterGoalUiState(
      settings: saved ?? const WaterSettings(),
      isFirstTime: saved == null,
    );
  }

  void _update(WaterSettings Function(WaterSettings) change) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(
      s.copyWith(settings: change(s.settings), errors: const {}),
    );
  }

  void setGoal(int glasses) => _update(
    (s) => s.copyWith(
      goalGlasses: glasses.clamp(WaterRules.minGoal, WaterRules.maxGoal),
    ),
  );
  void setGlassSize(int ml) => _update((s) => s.copyWith(mlPerGlass: ml));
  void setWake(int minute) => _update((s) => s.copyWith(wakeMinute: minute));
  void setSleep(int minute) => _update((s) => s.copyWith(sleepMinute: minute));
  void setReminders(bool on) =>
      _update((s) => s.copyWith(remindersEnabled: on));

  /// Renvoie true une fois enregistré (l'écran se ferme alors).
  Future<bool> save() async {
    final s = state.value;
    if (s == null) return false;
    final errors = WaterRules.validate(s.settings);
    if (errors.isNotEmpty) {
      state = AsyncData(s.copyWith(errors: errors));
      return false;
    }
    state = AsyncData(s.copyWith(saving: true));
    try {
      await ref.read(saveWaterSettingsProvider)(s.settings);
      return true;
    } on InvalidWaterSettingsException catch (e) {
      state = AsyncData(s.copyWith(errors: e.errors, saving: false));
      return false;
    }
  }
}
