/// Objectif d'eau choisi par l'utilisateur. L'application ne recommande
/// aucune quantité : l'objectif reste personnel.
class WaterSettings {
  const WaterSettings({
    this.goalGlasses = 5,
    this.mlPerGlass = 250,
    this.wakeMinute = 7 * 60,
    this.sleepMinute = 22 * 60,
    this.remindersEnabled = true,
  });

  /// Objectif du jour, en verres.
  final int goalGlasses;
  final int mlPerGlass;

  /// Heures de réveil et de coucher (minutes depuis minuit) : les rappels
  /// sont répartis entre les deux.
  final int wakeMinute;
  final int sleepMinute;
  final bool remindersEnabled;

  int get goalMl => goalGlasses * mlPerGlass;

  WaterSettings copyWith({
    int? goalGlasses,
    int? mlPerGlass,
    int? wakeMinute,
    int? sleepMinute,
    bool? remindersEnabled,
  }) => WaterSettings(
    goalGlasses: goalGlasses ?? this.goalGlasses,
    mlPerGlass: mlPerGlass ?? this.mlPerGlass,
    wakeMinute: wakeMinute ?? this.wakeMinute,
    sleepMinute: sleepMinute ?? this.sleepMinute,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
  );
}
