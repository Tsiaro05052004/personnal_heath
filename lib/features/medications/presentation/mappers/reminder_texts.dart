import '../../domain/entities/medication_reminder.dart';
import 'dose_labels.dart';

/// Texte des notifications de rappel. Jamais de conseil médical : on
/// rappelle seulement ce que l'ordonnance prévoit.
abstract final class ReminderTexts {
  static ({String title, String body}) build(MedicationReminder r) {
    final hour = DoseLabels.hour(r.scheduledAt);
    final what =
        '${r.medication.displayName} — Prendre ${DoseLabels.summary(r.medication)}';
    return switch (r.kind) {
      ReminderKind.dose => (
        title: "C'est l'heure de votre médicament",
        body: '$hour · $what',
      ),
      ReminderKind.followUp => (
        title: 'Avez-vous pris votre médicament ?',
        body: 'Prévu à $hour · $what',
      ),
      ReminderKind.snooze => (
        title: 'Rappel : votre médicament',
        body: 'Prévu à $hour · $what',
      ),
    };
  }
}
