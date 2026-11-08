import '../entities/intake_log.dart';
import '../entities/intake_status.dart';
import '../entities/scheduled_intake.dart';
import '../repositories/medication_repository.dart';
import '../services/intake_planner.dart';

/// « Confirmer la prise » : enregistre l'heure RÉELLE (une confirmation en
/// retard garde l'heure de confirmation) et la quantité prévue par
/// l'ordonnance — l'application ne modifie jamais la dose.
/// (Étape 3 : annulera aussi le 2e rappel et l'alarme de cette prise.)
class ConfirmIntake {
  const ConfirmIntake(this._repository);

  final MedicationRepository _repository;

  Future<void> call(ScheduledIntake intake, DateTime now) {
    if (!IntakePlanner.canConfirm(intake, now)) {
      throw StateError('Cette prise ne peut pas être confirmée maintenant.');
    }
    return _repository.saveIntakeLog(
      IntakeLog(
        id: intake.log?.id ?? '',
        medicationId: intake.medication.id,
        scheduledAt: intake.scheduledAt,
        status: IntakeStatus.taken,
        takenAt: now,
        quantityTaken: intake.medication.quantityPerIntake,
      ),
    );
  }
}
