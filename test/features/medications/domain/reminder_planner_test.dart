import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_log.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_status.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication_reminder.dart';
import 'package:personnal_heath/features/medications/domain/services/reminder_planner.dart';

void main() {
  final now = DateTime(2026, 11, 8, 14, 10);
  Medication med({DateTime? end, List<DoseTime>? times}) => Medication(
    id: 'para',
    name: 'Paracétamol',
    startDate: DateTime(2026, 11, 1),
    endDate: end,
    doseTimes:
        times ?? const [DoseTime(8, 0), DoseTime(14, 0), DoseTime(20, 0)],
  );

  String describe(MedicationReminder r) =>
      '${r.kind.name} ${r.fireAt.day}/${r.fireAt.hour}h${r.fireAt.minute}';

  test("rappel à l'heure puis 2e rappel 30 min après", () {
    final reminders = ReminderPlanner.plan(
      medications: [med()],
      logs: const [],
      now: now,
    );

    expect(reminders.take(4).map(describe), [
      'followUp 8/14h30', // 14h00 pas encore confirmée
      'dose 8/20h0',
      'followUp 8/20h30',
      'dose 9/8h0',
    ]);
  });

  test("une prise confirmée ou déclarée non prise n'a plus de rappel", () {
    final reminders = ReminderPlanner.plan(
      medications: [med()],
      logs: [
        IntakeLog(
          medicationId: 'para',
          scheduledAt: DateTime(2026, 11, 8, 14),
          status: IntakeStatus.taken,
        ),
        IntakeLog(
          medicationId: 'para',
          scheduledAt: DateTime(2026, 11, 8, 20),
          status: IntakeStatus.missed,
        ),
      ],
      now: now,
    );

    expect(reminders.first.fireAt, DateTime(2026, 11, 9, 8));
  });

  test('les rappels s’arrêtent à la date de fin', () {
    final reminders = ReminderPlanner.plan(
      medications: [med(end: DateTime(2026, 11, 9))],
      logs: const [],
      now: now,
    );

    expect(reminders.last.fireAt, DateTime(2026, 11, 9, 20, 30));
  });

  test('fenêtre de 14 jours, plafonnée', () {
    final fourTimes = med(
      times: const [
        DoseTime(6, 0),
        DoseTime(10, 0),
        DoseTime(14, 0),
        DoseTime(18, 0),
      ],
    );
    final many = [
      for (var i = 0; i < 5; i++)
        Medication(
          id: 'm$i',
          name: 'M$i',
          startDate: fourTimes.startDate,
          doseTimes: fourTimes.doseTimes,
        ),
    ];

    final one = ReminderPlanner.plan(
      medications: [med()],
      logs: const [],
      now: now,
    );
    expect(one.last.fireAt.isAfter(now.add(ReminderPlanner.horizon)), isFalse);
    expect(one.last.fireAt.day, 22);

    final capped = ReminderPlanner.plan(
      medications: many,
      logs: const [],
      now: now,
    );
    expect(capped, hasLength(ReminderPlanner.maxReminders));
    // On garde les plus proches.
    expect(capped.first.fireAt, DateTime(2026, 11, 8, 14, 30));
  });
}
