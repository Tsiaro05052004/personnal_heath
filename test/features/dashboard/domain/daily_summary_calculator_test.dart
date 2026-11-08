import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/features/dashboard/domain/services/daily_summary_calculator.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_log.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_status.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';
import 'package:personnal_heath/features/medications/domain/entities/scheduled_intake.dart';
import 'package:personnal_heath/features/medications/domain/services/intake_planner.dart';

void main() {
  final para = Medication(
    id: 'para',
    name: 'Paracétamol',
    startDate: DateTime(2026, 11, 1),
    doseTimes: const [DoseTime(8, 0), DoseTime(14, 0), DoseTime(20, 0)],
  );
  final amox = Medication(
    id: 'amox',
    name: 'Amoxicilline',
    startDate: DateTime(2026, 11, 1),
    doseTimes: const [DoseTime(8, 0), DoseTime(20, 0)],
  );

  test('regroupe les prises par heure (maquette 2)', () {
    final plan = IntakePlanner.planDay(
      medications: [para, amox],
      logs: [
        IntakeLog(
          medicationId: 'para',
          scheduledAt: DateTime(2026, 11, 8, 8),
          status: IntakeStatus.taken,
        ),
        IntakeLog(
          medicationId: 'amox',
          scheduledAt: DateTime(2026, 11, 8, 8),
          status: IntakeStatus.taken,
        ),
      ],
      day: DateTime(2026, 11, 8),
      now: DateTime(2026, 11, 8, 14, 10),
    );

    final groups = DailySummaryCalculator.groupByTime(plan);
    expect(
      groups.map(
        (g) => '${g.at.hour}h ${g.medicationNames.join(', ')} ${g.state.name}',
      ),
      [
        '8h Paracétamol, Amoxicilline taken',
        '14h Paracétamol pending',
        '20h Paracétamol, Amoxicilline upcoming',
      ],
    );

    final summary = DailySummaryCalculator.summarize(plan, null);
    expect(summary.nextIntake!.scheduledAt.hour, 14);
    expect(summary.water, isNull);
  });

  test("l'état d'un groupe met en avant ce qui demande une action", () {
    ScheduledIntake i(IntakeState s) => ScheduledIntake(
      medication: para,
      scheduledAt: DateTime(2026, 11, 8, 8),
      state: s,
    );
    IntakeState of(List<IntakeState> s) =>
        DailySummaryCalculator.groupState(s.map(i).toList());

    expect(of([IntakeState.taken, IntakeState.pending]), IntakeState.pending);
    expect(
      of([IntakeState.taken, IntakeState.unconfirmed]),
      IntakeState.unconfirmed,
    );
    expect(of([IntakeState.taken, IntakeState.missed]), IntakeState.missed);
    expect(of([IntakeState.taken, IntakeState.taken]), IntakeState.taken);
  });
}
