import 'medication.dart';
import 'scheduled_intake.dart';

/// Les prises d'un médicament un jour donné (une carte de la liste).
class MedicationDay {
  const MedicationDay({required this.medication, required this.intakes});

  final Medication medication;
  final List<ScheduledIntake> intakes;

  int get confirmedCount => intakes.where((i) => i.isTaken).length;
}

/// Toutes les prises prévues d'une journée.
class DayPlan {
  const DayPlan({
    required this.day,
    required this.intakes,
    required this.medications,
  });

  /// Minuit du jour concerné.
  final DateTime day;

  /// Toutes les prises du jour, par heure.
  final List<ScheduledIntake> intakes;

  /// Les mêmes prises regroupées par médicament.
  final List<MedicationDay> medications;

  /// « 2 prises confirmées sur 5 » : une prise ≠ un comprimé.
  int get totalCount => intakes.length;
  int get confirmedCount => intakes.where((i) => i.isTaken).length;

  /// Unités réellement consommées (distinct du nombre de prises).
  double get unitsTaken => intakes
      .where((i) => i.isTaken)
      .fold(0, (sum, i) => sum + (i.log?.quantityTaken ?? 0));
}
