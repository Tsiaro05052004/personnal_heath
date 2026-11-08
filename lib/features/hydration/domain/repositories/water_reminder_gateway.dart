import '../entities/water_reminder.dart';

/// Rappels d'eau confiés au système (implémenté dans data/).
abstract interface class WaterReminderGateway {
  /// Remplace tous les rappels d'eau planifiés par [reminders].
  Future<void> replaceAll(List<WaterReminder> reminders);
}
