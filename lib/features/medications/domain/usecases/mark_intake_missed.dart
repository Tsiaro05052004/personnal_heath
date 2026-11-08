import '../entities/intake_log.dart';
import '../entities/intake_status.dart';
import '../entities/scheduled_intake.dart';
import '../repositories/medication_repository.dart';
import '../services/intake_planner.dart';

/// « Je ne l'ai pas pris » : seul l'utilisateur peut déclarer une prise
/// oubliée. Aucune compensation n'est proposée (jamais de dose doublée).
class MarkIntakeMissed {
  const MarkIntakeMissed(this._repository);

  final MedicationRepository _repository;

  Future<void> call(ScheduledIntake intake, DateTime now) {
    if (!IntakePlanner.canMarkMissed(intake, now)) {
      throw StateError('Cette prise ne peut pas être déclarée oubliée.');
    }
    return _repository.saveIntakeLog(
      IntakeLog(
        id: intake.log?.id ?? '',
        medicationId: intake.medication.id,
        scheduledAt: intake.scheduledAt,
        status: IntakeStatus.missed,
      ),
    );
  }
}
