import '../../../hydration/domain/entities/water_day.dart';
import '../../../medications/domain/entities/day_plan.dart';
import '../../../medications/domain/entities/scheduled_intake.dart';
import 'intake_group.dart';

/// Bilan d'une journée : médicaments et eau (Accueil, puis Historique).
class DailySummary {
  const DailySummary({
    required this.plan,
    required this.water,
    required this.groups,
    required this.nextIntake,
  });

  final DayPlan plan;

  /// null si l'objectif d'eau n'est pas encore défini.
  final WaterDay? water;

  /// Prises regroupées par heure, dans l'ordre de la journée.
  final List<IntakeGroup> groups;

  /// Prise à mettre en avant (la plus ancienne en attente, sinon la
  /// prochaine à venir) ; null quand tout est fait.
  final ScheduledIntake? nextIntake;

  bool get hasMedications => plan.totalCount > 0;
}
