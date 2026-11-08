import '../entities/day_plan.dart';
import '../entities/intake_log.dart';
import '../entities/intake_status.dart';
import '../entities/medication.dart';
import '../entities/scheduled_intake.dart';

/// Règles du suivi des prises (cahier des charges, section « Suivi »).
abstract final class IntakePlanner {
  /// Après l'heure prévue, la prise reste « en attente » pendant ce délai,
  /// puis devient « non confirmée » (jamais « oubliée » automatiquement).
  static const pendingWindow = Duration(hours: 2);

  /// On peut confirmer une prise un peu avant l'heure (ex. 07h45 pour 08h00).
  static const earlyConfirmWindow = Duration(minutes: 30);

  /// Prises prévues le jour [day], avec leur état à l'instant [now].
  /// [logs] peut contenir des prises d'autres jours : elles sont ignorées.
  static DayPlan planDay({
    required List<Medication> medications,
    required List<IntakeLog> logs,
    required DateTime day,
    required DateTime now,
  }) {
    final date = dateOnly(day);
    final logsByKey = {
      for (final log in logs) _key(log.medicationId, log.scheduledAt): log,
    };

    final byMedication = <MedicationDay>[];
    for (final medication in medications) {
      if (!medication.isActiveOn(date)) continue;
      final intakes = [
        for (final time in medication.doseTimes)
          _intake(
            medication,
            time.on(date),
            logsByKey[_key(medication.id, time.on(date))],
            now,
          ),
      ];
      if (intakes.isNotEmpty) {
        byMedication.add(
          MedicationDay(medication: medication, intakes: intakes),
        );
      }
    }
    byMedication.sort(
      (a, b) =>
          a.intakes.first.scheduledAt.compareTo(b.intakes.first.scheduledAt),
    );

    final all = [for (final m in byMedication) ...m.intakes]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return DayPlan(day: date, intakes: all, medications: byMedication);
  }

  /// État affiché d'une prise prévue à [scheduledAt].
  static IntakeState stateOf(
    DateTime scheduledAt,
    IntakeLog? log,
    DateTime now,
  ) {
    if (log != null) {
      return log.status == IntakeStatus.taken
          ? IntakeState.taken
          : IntakeState.missed;
    }
    if (now.isBefore(scheduledAt)) return IntakeState.upcoming;
    if (now.difference(scheduledAt) < pendingWindow) return IntakeState.pending;
    return IntakeState.unconfirmed;
  }

  /// La prise peut-elle être confirmée maintenant ? Une prise déclarée
  /// oubliée peut encore être confirmée (l'utilisateur s'est trompé).
  static bool canConfirm(ScheduledIntake intake, DateTime now) =>
      intake.state != IntakeState.taken &&
      !intake.scheduledAt.subtract(earlyConfirmWindow).isAfter(now);

  /// La prise peut-elle être déclarée oubliée ? Seulement une fois l'heure
  /// passée et si elle n'a pas été confirmée.
  static bool canMarkMissed(ScheduledIntake intake, DateTime now) =>
      (intake.state == IntakeState.pending ||
          intake.state == IntakeState.unconfirmed) &&
      !now.isBefore(intake.scheduledAt);

  /// Prise à mettre en avant : la plus ancienne en attente, sinon la
  /// prochaine à venir. Null quand tout est fait pour la journée.
  static ScheduledIntake? nextIntake(DayPlan plan) {
    for (final state in [IntakeState.pending, IntakeState.upcoming]) {
      for (final intake in plan.intakes) {
        if (intake.state == state) return intake;
      }
    }
    return null;
  }

  static ScheduledIntake _intake(
    Medication medication,
    DateTime scheduledAt,
    IntakeLog? log,
    DateTime now,
  ) => ScheduledIntake(
    medication: medication,
    scheduledAt: scheduledAt,
    log: log,
    state: stateOf(scheduledAt, log, now),
  );

  static String _key(String medicationId, DateTime at) =>
      '$medicationId@${at.millisecondsSinceEpoch}';
}
