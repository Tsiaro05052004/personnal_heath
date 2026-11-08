import 'intake_log.dart';
import 'intake_status.dart';
import 'medication.dart';

/// État AFFICHÉ d'une prise prévue (calculé, jamais stocké).
enum IntakeState {
  /// Confirmée par l'utilisateur.
  taken,

  /// Déclarée oubliée par l'utilisateur lui-même.
  missed,

  /// L'heure est passée depuis peu : on attend la confirmation.
  pending,

  /// L'heure est passée depuis longtemps sans confirmation. JAMAIS
  /// considérée comme oubliée automatiquement.
  unconfirmed,

  /// Plus tard.
  upcoming,
}

/// Une prise prévue un jour donné, avec ce que l'utilisateur en a dit.
class ScheduledIntake {
  const ScheduledIntake({
    required this.medication,
    required this.scheduledAt,
    required this.state,
    this.log,
  });

  final Medication medication;
  final DateTime scheduledAt;
  final IntakeState state;
  final IntakeLog? log;

  bool get isTaken => state == IntakeState.taken;

  /// Heure réelle si la prise est confirmée.
  DateTime? get takenAt =>
      log?.status == IntakeStatus.taken ? log?.takenAt : null;
}
