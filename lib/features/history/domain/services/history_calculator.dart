import '../../../dashboard/domain/entities/daily_summary.dart';
import '../../../dashboard/domain/services/daily_summary_calculator.dart';
import '../../../hydration/domain/entities/water_day.dart';
import '../../../hydration/domain/entities/water_log.dart';
import '../../../hydration/domain/entities/water_settings.dart';
import '../../../medications/domain/entities/intake_log.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/domain/entities/scheduled_intake.dart';
import '../../../medications/domain/services/intake_planner.dart';
import '../entities/history_day.dart';

/// Périodes de l'historique : les jours AVANT aujourd'hui (la journée en
/// cours n'est pas finie, elle est sur l'Accueil).
enum HistoryPeriod {
  week(7),
  month(30);

  const HistoryPeriod(this.days);

  final int days;
}

/// Calcule l'historique à partir des données des autres features.
abstract final class HistoryCalculator {
  /// [from, to[ : jours à couvrir.
  static ({DateTime from, DateTime to}) range(
    HistoryPeriod period,
    DateTime now,
  ) {
    final today = dateOnly(now);
    return (
      from: DateTime(today.year, today.month, today.day - period.days),
      to: today,
    );
  }

  static HistoryPeriodSummary build({
    required HistoryPeriod period,
    required DateTime now,
    required List<Medication> medications,
    required List<IntakeLog> intakeLogs,
    required WaterSettings? waterSettings,
    required List<WaterLog> waterLogs,
  }) {
    final (:from, :to) = range(period, now);
    final days = <HistoryDay>[];
    for (
      var day = DateTime(to.year, to.month, to.day - 1);
      !day.isBefore(from);
      day = DateTime(day.year, day.month, day.day - 1)
    ) {
      final next = DateTime(day.year, day.month, day.day + 1);
      final dayWater = [
        for (final log in waterLogs)
          if (!log.drankAt.isBefore(day) && log.drankAt.isBefore(next)) log,
      ];
      final plan = IntakePlanner.planDay(
        medications: medications,
        logs: intakeLogs,
        day: day,
        // Journée terminée : tout ce qui n'a pas de réponse est « non
        // confirmé ».
        now: next.add(IntakePlanner.pendingWindow),
      );
      // Jour sans aucun suivi (avant l'installation…) : on ne l'affiche pas.
      if (plan.totalCount == 0 && dayWater.isEmpty) continue;

      final water = waterSettings == null
          ? null
          : WaterDay(day: day, settings: waterSettings, logs: dayWater);
      days.add(_day(DailySummaryCalculator.summarize(plan, water)));
    }
    return HistoryPeriodSummary(days: days);
  }

  static HistoryDay _day(DailySummary dailySummary) {
    final intakes = dailySummary.plan.intakes;
    int count(IntakeState s) => intakes.where((i) => i.state == s).length;
    final confirmed = count(IntakeState.taken);
    final waterOk = dailySummary.water?.goalReached ?? true;
    return HistoryDay(
      summary: dailySummary,
      planned: intakes.length,
      confirmed: confirmed,
      late: intakes.where(IntakePlanner.isLate).length,
      unconfirmed: count(IntakeState.unconfirmed),
      missed: count(IntakeState.missed),
      verdict: confirmed == intakes.length && waterOk
          ? DayVerdict.respected
          : DayVerdict.partial,
    );
  }
}
