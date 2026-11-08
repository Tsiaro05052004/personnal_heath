import 'intake_status.dart';

/// Une prise sur laquelle l'utilisateur a agi : confirmée ou déclarée
/// oubliée. Sans IntakeLog, une prise passée est « non confirmée ».
class IntakeLog {
  const IntakeLog({
    this.id = '',
    required this.medicationId,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
    this.quantityTaken,
  });

  /// Vide tant que la prise n'est pas enregistrée.
  final String id;
  final String medicationId;

  /// Date et heure PRÉVUES.
  final DateTime scheduledAt;
  final IntakeStatus status;

  /// Heure RÉELLE de la prise (confirmée en retard = heure de confirmation).
  final DateTime? takenAt;

  /// Unités réellement prises.
  final double? quantityTaken;
}
