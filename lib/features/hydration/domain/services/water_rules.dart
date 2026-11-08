import '../entities/water_settings.dart';

/// Raisons pour lesquelles un objectif d'eau ne peut pas être enregistré.
enum WaterSettingsError { invalidGoal, invalidGlassSize, sleepBeforeWake }

class InvalidWaterSettingsException implements Exception {
  const InvalidWaterSettingsException(this.errors);

  final Set<WaterSettingsError> errors;
}

abstract final class WaterRules {
  static const minGoal = 1;
  static const maxGoal = 20;
  static const glassSizes = [150, 200, 250, 300, 330, 500];

  /// Au moins 2 h entre réveil et coucher, sans passer minuit.
  static const minAwakeMinutes = 120;

  static Set<WaterSettingsError> validate(WaterSettings s) => {
    if (s.goalGlasses < minGoal || s.goalGlasses > maxGoal)
      WaterSettingsError.invalidGoal,
    if (s.mlPerGlass < 50 || s.mlPerGlass > 1000)
      WaterSettingsError.invalidGlassSize,
    if (s.sleepMinute - s.wakeMinute < minAwakeMinutes)
      WaterSettingsError.sleepBeforeWake,
  };
}
