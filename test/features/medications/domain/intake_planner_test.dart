import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_log.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_status.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';
import 'package:personnal_heath/features/medications/domain/entities/scheduled_intake.dart';
import 'package:personnal_heath/features/medications/domain/services/intake_planner.dart';

void main() {
  final day = DateTime(2026, 11, 8);
  final paracetamol = Medication(
    id: 'para',
    name: 'Paracétamol',
    dosage: '500 mg',
    quantityPerIntake: 2,
    startDate: DateTime(2026, 11, 1),
    doseTimes: const [DoseTime(20, 0), DoseTime(8, 0), DoseTime(14, 0)],
  );
  final amoxicilline = Medication(
    id: 'amox',
    name: 'Amoxicilline',
    startDate: DateTime(2026, 11, 5),
    endDate: DateTime(2026, 11, 12),
    doseTimes: const [DoseTime(8, 0), DoseTime(20, 0)],
  );

  IntakeLog taken(Medication m, int hour, {int minute = 5}) => IntakeLog(
    medicationId: m.id,
    scheduledAt: DateTime(2026, 11, 8, hour),
    status: IntakeStatus.taken,
    takenAt: DateTime(2026, 11, 8, hour, minute),
    quantityTaken: m.quantityPerIntake,
  );

  group('planDay', () {
    test('liste les prises du jour triées par heure', () {
      final plan = IntakePlanner.planDay(
        medications: [paracetamol, amoxicilline],
        logs: const [],
        day: day,
        now: DateTime(2026, 11, 8, 7),
      );

      expect(plan.totalCount, 5);
      expect(
        plan.intakes.map((i) => '${i.scheduledAt.hour}h ${i.medication.id}'),
        ['8h para', '8h amox', '14h para', '20h para', '20h amox'],
      );
      expect(plan.medications.first.intakes.map((i) => i.scheduledAt.hour), [
        8,
        14,
        20,
      ]);
    });

    test('une prise = une confirmation, pas un nombre de comprimés', () {
      final plan = IntakePlanner.planDay(
        medications: [paracetamol],
        logs: [taken(paracetamol, 8)],
        day: day,
        now: DateTime(2026, 11, 8, 9),
      );

      expect(plan.confirmedCount, 1);
      expect(plan.unitsTaken, 2);
    });

    test('après la date de fin, plus aucune prise prévue', () {
      final plan = IntakePlanner.planDay(
        medications: [amoxicilline],
        logs: const [],
        day: DateTime(2026, 11, 13),
        now: DateTime(2026, 11, 13, 9),
      );
      expect(plan.totalCount, 0);

      final lastDay = IntakePlanner.planDay(
        medications: [amoxicilline],
        logs: const [],
        day: DateTime(2026, 11, 12),
        now: DateTime(2026, 11, 12, 9),
      );
      expect(lastDay.totalCount, 2);
    });

    test('avant la date de début, aucune prise prévue', () {
      final plan = IntakePlanner.planDay(
        medications: [amoxicilline],
        logs: const [],
        day: DateTime(2026, 11, 4),
        now: DateTime(2026, 11, 4, 9),
      );
      expect(plan.totalCount, 0);
    });
  });

  group('état d’une prise', () {
    final at = DateTime(2026, 11, 8, 14);

    test('à venir avant l’heure', () {
      expect(
        IntakePlanner.stateOf(at, null, DateTime(2026, 11, 8, 13, 59)),
        IntakeState.upcoming,
      );
    });

    test('en attente juste après l’heure', () {
      expect(
        IntakePlanner.stateOf(at, null, DateTime(2026, 11, 8, 14, 10)),
        IntakeState.pending,
      );
    });

    test('non confirmée (JAMAIS oubliée) longtemps après', () {
      expect(
        IntakePlanner.stateOf(at, null, DateTime(2026, 11, 8, 23)),
        IntakeState.unconfirmed,
      );
    });

    test('oubliée seulement si l’utilisateur le déclare', () {
      final log = IntakeLog(
        medicationId: 'para',
        scheduledAt: at,
        status: IntakeStatus.missed,
      );
      expect(
        IntakePlanner.stateOf(at, log, DateTime(2026, 11, 8, 23)),
        IntakeState.missed,
      );
    });
  });

  group('actions possibles', () {
    ScheduledIntake intake(IntakeState state, {int hour = 14}) =>
        ScheduledIntake(
          medication: paracetamol,
          scheduledAt: DateTime(2026, 11, 8, hour),
          state: state,
        );

    test('on peut confirmer 30 min avant, pas plus tôt', () {
      final i = intake(IntakeState.upcoming);
      expect(IntakePlanner.canConfirm(i, DateTime(2026, 11, 8, 13, 30)), true);
      expect(IntakePlanner.canConfirm(i, DateTime(2026, 11, 8, 13, 29)), false);
    });

    test(
      'on peut confirmer en retard, et après avoir déclaré « non pris »',
      () {
        final late = DateTime(2026, 11, 8, 22);
        expect(
          IntakePlanner.canConfirm(intake(IntakeState.unconfirmed), late),
          true,
        );
        expect(
          IntakePlanner.canConfirm(intake(IntakeState.missed), late),
          true,
        );
        expect(
          IntakePlanner.canConfirm(intake(IntakeState.taken), late),
          false,
        );
      },
    );

    test('« non pris » seulement une fois l’heure passée', () {
      expect(
        IntakePlanner.canMarkMissed(
          intake(IntakeState.upcoming),
          DateTime(2026, 11, 8, 13),
        ),
        false,
      );
      expect(
        IntakePlanner.canMarkMissed(
          intake(IntakeState.pending),
          DateTime(2026, 11, 8, 14, 5),
        ),
        true,
      );
      expect(
        IntakePlanner.canMarkMissed(
          intake(IntakeState.taken),
          DateTime(2026, 11, 8, 15),
        ),
        false,
      );
    });

    test('prochaine prise : la plus ancienne en attente d’abord', () {
      final plan = IntakePlanner.planDay(
        medications: [paracetamol],
        logs: [taken(paracetamol, 8)],
        day: day,
        now: DateTime(2026, 11, 8, 14, 10),
      );
      final next = IntakePlanner.nextIntake(plan)!;
      expect(next.scheduledAt.hour, 14);
      expect(next.state, IntakeState.pending);
    });
  });
}
