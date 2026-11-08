/// Sortes de rappel d'eau.
enum WaterReminderKind {
  /// « Un petit verre d'eau ? » si l'objectif intermédiaire n'est pas
  /// atteint à cette heure-là.
  nudge,

  /// Bilan avant le coucher : objectif atteint ou non.
  summary,
}

/// Un rappel d'eau à planifier.
class WaterReminder {
  const WaterReminder({
    required this.kind,
    required this.at,
    required this.glasses,
    required this.goal,
  });

  final WaterReminderKind kind;
  final DateTime at;

  /// Verres déjà bus ce jour-là au moment du calcul.
  final int glasses;
  final int goal;
}
