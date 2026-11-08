import '../entities/scheduled_intake.dart';
import '../repositories/reminder_gateway.dart';

/// L'utilisateur quitte l'écran d'alarme sans répondre : la sonnerie
/// s'arrête, la prise reste en attente et le 2e rappel reste prévu.
class SilenceReminder {
  const SilenceReminder(this._gateway);

  final ReminderGateway _gateway;

  Future<void> call(ScheduledIntake intake) =>
      _gateway.silence(intake.medication.id, intake.scheduledAt);
}
