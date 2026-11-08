import '../entities/intake_log.dart';
import '../entities/intake_status.dart';
import '../entities/scheduled_intake.dart';
import '../repositories/medication_repository.dart';
import '../repositories/reminder_gateway.dart';
import '../services/intake_planner.dart';

/// « Je ne l'ai pas pris » : seul l'utilisateur peut déclarer une prise
/// oubliée. Aucune compensation n'est proposée (jamais de dose doublée).
class MarkIntakeMissed {
  const MarkIntakeMissed(this._repository, this._gateway);

  final MedicationRepository _repository;
  final ReminderGateway _gateway;

  Future<void> call(ScheduledIntake intake, DateTime now) async {
    if (!IntakePlanner.canMarkMissed(intake, now)) {
      throw StateError('Cette prise ne peut pas être déclarée oubliée.');
    }
    await _repository.saveIntakeLog(
      IntakeLog(
        id: intake.log?.id ?? '',
        medicationId: intake.medication.id,
        scheduledAt: intake.scheduledAt,
        status: IntakeStatus.missed,
      ),
    );
    // Plus de 2e rappel ni de rappel « plus tard » pour cette prise, et
    // la notification déjà affichée disparaît.
    await _gateway.cancelFor(intake.medication.id, intake.scheduledAt);
  }
}
