import '../../../dashboard/domain/entities/daily_summary.dart';

/// Bilan d'un jour passé.
enum DayVerdict {
  /// Toutes les prises confirmées et objectif d'eau atteint.
  respected,

  /// Une partie seulement. Jamais « raté » : on encourage, on ne juge pas.
  partial,
}

/// Un jour de l'historique (maquette 8).
class HistoryDay {
  const HistoryDay({
    required this.summary,
    required this.planned,
    required this.confirmed,
    required this.late,
    required this.unconfirmed,
    required this.missed,
    required this.verdict,
  });

  final DailySummary summary;
  DateTime get day => summary.plan.day;

  /// Prises prévues et confirmées (une prise ≠ un comprimé).
  final int planned;
  final int confirmed;

  /// Confirmées plus de 30 min après l'heure (comptées dans [confirmed]).
  final int late;

  /// Sans réponse de l'utilisateur : JAMAIS comptées comme oubliées.
  final int unconfirmed;

  /// Déclarées « non prises » par l'utilisateur.
  final int missed;
  final DayVerdict verdict;
}

/// Bilan d'une période (« Cette semaine », « Ce mois »).
class HistoryPeriodSummary {
  const HistoryPeriodSummary({required this.days});

  /// Jours suivis, du plus récent au plus ancien.
  final List<HistoryDay> days;

  int get planned => days.fold(0, (n, d) => n + d.planned);
  int get confirmed => days.fold(0, (n, d) => n + d.confirmed);

  /// Jours où l'eau était suivie, et ceux où l'objectif a été atteint.
  int get waterDays => days.where((d) => d.summary.water != null).length;
  int get waterGoalDays =>
      days.where((d) => d.summary.water?.goalReached ?? false).length;
}
