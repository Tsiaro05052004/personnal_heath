import '../repositories/water_reminder_gateway.dart';
import '../repositories/water_repository.dart';
import '../services/water_reminder_planner.dart';

/// Recalcule les rappels d'eau : au démarrage, au retour dans l'appli,
/// après chaque verre et après un changement d'objectif.
class RescheduleWaterReminders {
  const RescheduleWaterReminders(this._repository, this._gateway, this._now);

  final WaterRepository _repository;
  final WaterReminderGateway _gateway;
  final DateTime Function() _now;

  Future<void> call() async {
    final now = _now();
    final settings = await _repository.watchSettings().first;
    if (settings == null) {
      await _gateway.replaceAll(const []);
      return;
    }
    final today = DateTime(now.year, now.month, now.day);
    final logs = await _repository
        .watchLogs(today, DateTime(today.year, today.month, today.day + 1))
        .first;
    await _gateway.replaceAll(
      WaterReminderPlanner.plan(
        settings: settings,
        glassesToday: logs.length,
        now: now,
      ),
    );
  }
}
