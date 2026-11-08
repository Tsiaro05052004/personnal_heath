import 'medication.dart';

/// Les trois sortes de rappel d'une prise.
enum ReminderKind {
  /// À l'heure prévue.
  dose,

  /// Deuxième rappel si la prise n'est toujours pas confirmée.
  followUp,

  /// « Me le rappeler dans 10 min », demandé depuis l'écran d'alarme.
  snooze,
}

/// Un rappel à planifier pour une prise.
class MedicationReminder {
  const MedicationReminder({
    required this.kind,
    required this.medication,
    required this.scheduledAt,
    required this.fireAt,
  });

  final ReminderKind kind;
  final Medication medication;

  /// Heure PRÉVUE de la prise concernée.
  final DateTime scheduledAt;

  /// Heure à laquelle le rappel sonne.
  final DateTime fireAt;

  String get medicationId => medication.id;
}
