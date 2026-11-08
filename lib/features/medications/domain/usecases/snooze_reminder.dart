import '../entities/medication_reminder.dart';
import '../entities/scheduled_intake.dart';
import '../repositories/reminder_gateway.dart';
import '../services/reminder_planner.dart';

/// « Me le rappeler dans 10 min ». La prise reste « en attente ».
class SnoozeReminder {
  const SnoozeReminder(this._gateway);

  final ReminderGateway _gateway;

  /// Renvoie l'heure du nouveau rappel.
  Future<DateTime> call(ScheduledIntake intake, DateTime now) async {
    final fireAt = now.add(ReminderPlanner.snoozeDelay);
    await _gateway.cancelFor(intake.medication.id, intake.scheduledAt);
    await _gateway.snooze(
      MedicationReminder(
        kind: ReminderKind.snooze,
        medication: intake.medication,
        scheduledAt: intake.scheduledAt,
        fireAt: fireAt,
      ),
    );
    return fireAt;
  }
}
