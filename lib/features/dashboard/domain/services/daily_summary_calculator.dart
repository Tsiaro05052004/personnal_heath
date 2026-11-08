import '../../../hydration/domain/entities/water_day.dart';
import '../../../medications/domain/entities/day_plan.dart';
import '../../../medications/domain/entities/scheduled_intake.dart';
import '../../../medications/domain/services/intake_planner.dart';
import '../entities/daily_summary.dart';
import '../entities/intake_group.dart';

/// Calcule le bilan d'une journée à partir des autres features. Le tableau
/// de bord n'a pas de données à lui.
abstract final class DailySummaryCalculator {
  static DailySummary summarize(DayPlan plan, WaterDay? water) => DailySummary(
    plan: plan,
    water: water,
    groups: groupByTime(plan),
    nextIntake: IntakePlanner.nextIntake(plan),
  );

  static List<IntakeGroup> groupByTime(DayPlan plan) {
    final byTime = <DateTime, List<ScheduledIntake>>{};
    for (final intake in plan.intakes) {
      byTime.putIfAbsent(intake.scheduledAt, () => []).add(intake);
    }
    return [
      for (final MapEntry(key: at, value: intakes) in byTime.entries)
        IntakeGroup(at: at, intakes: intakes, state: groupState(intakes)),
    ];
  }

  /// État d'un groupe : ce qui demande une action passe en premier.
  /// Un groupe n'est « pris » que si toutes ses prises le sont.
  static IntakeState groupState(List<ScheduledIntake> intakes) {
    for (final state in const [
      IntakeState.pending,
      IntakeState.unconfirmed,
      IntakeState.upcoming,
      IntakeState.missed,
    ]) {
      if (intakes.any((i) => i.state == state)) return state;
    }
    return IntakeState.taken;
  }
}
