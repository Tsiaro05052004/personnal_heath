import '../entities/medication.dart';
import '../repositories/medication_repository.dart';
import '../repositories/reminder_gateway.dart';
import '../services/reminder_planner.dart';

/// Recalcule tous les rappels de prise à venir et les confie au système.
/// Appelé au démarrage, au retour dans l'appli et après chaque
/// modification de traitement ou de prise.
class RescheduleReminders {
  const RescheduleReminders(
    this._repository,
    this._gateway,
    this._now, {
    this.followUpDelay,
  });

  final MedicationRepository _repository;
  final ReminderGateway _gateway;
  final DateTime Function() _now;

  /// Délai du 2e rappel choisi par l'utilisateur.
  final Duration Function()? followUpDelay;

  Future<void> call() async {
    final now = _now();
    final from = dateOnly(now).subtract(const Duration(days: 1));
    final to = now.add(ReminderPlanner.horizon + const Duration(days: 1));
    final medications = await _repository.watchMedications().first;
    final logs = await _repository.watchIntakeLogs(from, to).first;
    await _gateway.replaceAll(
      ReminderPlanner.plan(
        medications: medications,
        logs: logs,
        now: now,
        followUpDelay:
            followUpDelay?.call() ?? ReminderPlanner.defaultFollowUpDelay,
      ),
      now,
    );
  }
}
