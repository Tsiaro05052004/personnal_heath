import '../entities/intake_log.dart';
import '../entities/medication.dart';
import '../entities/medication_reminder.dart';

/// Règles des rappels (cahier des charges : rappel à l'heure, 2e rappel si
/// la prise n'est pas confirmée, arrêt à la date de fin).
abstract final class ReminderPlanner {
  /// Délai du 2e rappel après l'heure prévue.
  static const followUpDelay = Duration(minutes: 30);

  /// Délai de « Me le rappeler plus tard ».
  static const snoozeDelay = Duration(minutes: 10);

  /// Les rappels sont confiés au système sur cette fenêtre glissante, puis
  /// recalculés à chaque ouverture de l'appli et à chaque modification.
  static const horizon = Duration(days: 14);

  /// Android limite le nombre d'alarmes d'une appli (~500) : on garde de
  /// la marge pour l'eau (étape 4) et on planifie d'abord les plus proches.
  static const maxReminders = 300;

  /// Rappels à venir après [now]. Une prise déjà confirmée ou déclarée non
  /// prise n'a plus de rappel. Après la date de fin : plus aucun rappel.
  static List<MedicationReminder> plan({
    required List<Medication> medications,
    required List<IntakeLog> logs,
    required DateTime now,
  }) {
    final handled = {
      for (final log in logs) _key(log.medicationId, log.scheduledAt),
    };
    final end = now.add(horizon);
    final reminders = <MedicationReminder>[];

    // On commence la veille : un 2e rappel peut tomber après minuit.
    var day = dateOnly(now).subtract(const Duration(days: 1));
    while (!day.isAfter(end)) {
      for (final medication in medications) {
        if (!medication.isActiveOn(day)) continue;
        for (final time in medication.doseTimes) {
          final at = time.on(day);
          if (handled.contains(_key(medication.id, at))) continue;
          for (final (kind, fireAt) in [
            (ReminderKind.dose, at),
            (ReminderKind.followUp, at.add(followUpDelay)),
          ]) {
            if (fireAt.isAfter(now) && !fireAt.isAfter(end)) {
              reminders.add(
                MedicationReminder(
                  kind: kind,
                  medication: medication,
                  scheduledAt: at,
                  fireAt: fireAt,
                ),
              );
            }
          }
        }
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }

    reminders.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return reminders.length > maxReminders
        ? reminders.sublist(0, maxReminders)
        : reminders;
  }

  static String _key(String medicationId, DateTime at) =>
      '$medicationId@${at.millisecondsSinceEpoch}';
}
