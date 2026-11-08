import '../entities/intake_log.dart';
import '../entities/intake_status.dart';
import '../entities/scheduled_intake.dart';
import '../repositories/medication_repository.dart';
import '../repositories/reminder_gateway.dart';
import '../services/intake_planner.dart';

/// « Confirmer la prise » : enregistre l'heure RÉELLE (une confirmation en
/// retard garde l'heure de confirmation) et la quantité prévue par
/// l'ordonnance — l'application ne modifie jamais la dose.
class ConfirmIntake {
  const ConfirmIntake(this._repository, this._gateway);

  final MedicationRepository _repository;
  final ReminderGateway _gateway;

  Future<void> call(ScheduledIntake intake, DateTime now) async {
    if (!IntakePlanner.canConfirm(intake, now)) {
      throw StateError('Cette prise ne peut pas être confirmée maintenant.');
    }
    await _repository.saveIntakeLog(
      IntakeLog(
        id: intake.log?.id ?? '',
        medicationId: intake.medication.id,
        scheduledAt: intake.scheduledAt,
        status: IntakeStatus.taken,
        takenAt: now,
        quantityTaken: intake.medication.quantityPerIntake,
      ),
    );
    // Plus de 2e rappel ni de rappel « plus tard » pour cette prise, et
    // la notification déjà affichée disparaît.
    await _gateway.cancelFor(intake.medication.id, intake.scheduledAt);
  }
}
