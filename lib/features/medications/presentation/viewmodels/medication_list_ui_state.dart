import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/day_plan.dart';
import '../../domain/entities/scheduled_intake.dart';
import '../../domain/services/intake_planner.dart';

/// Tout ce qu'affiche l'écran « Mes médicaments ».
class MedicationListUiState {
  const MedicationListUiState({
    required this.now,
    required this.today,
    required this.selectedDay,
    required this.plan,
  });

  final DateTime now;
  final DateTime today;
  final DateTime selectedDay;

  /// Prises du jour choisi (chargement / erreur / données).
  final AsyncValue<DayPlan> plan;

  /// Bandeau des jours : 2 jours avant et 2 jours après aujourd'hui.
  List<DateTime> get days => [
    for (var offset = -2; offset <= 2; offset++)
      DateTime(today.year, today.month, today.day + offset),
  ];

  bool get isToday => selectedDay == today;

  bool canConfirm(ScheduledIntake intake) =>
      IntakePlanner.canConfirm(intake, now);

  bool canMarkMissed(ScheduledIntake intake) =>
      IntakePlanner.canMarkMissed(intake, now);
}
