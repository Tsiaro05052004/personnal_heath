import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_day.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_log.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_reminder.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_settings.dart';
import 'package:personnal_heath/features/hydration/domain/services/water_reminder_planner.dart';
import 'package:personnal_heath/features/hydration/domain/services/water_rules.dart';

void main() {
  const fiveGlasses = WaterSettings(goalGlasses: 5);
  final day = DateTime(2026, 11, 8);
  String hm(DateTime d) => '${d.hour}h${d.minute.toString().padLeft(2, '0')}';

  test('rappels répartis entre réveil et coucher, objectif progressif', () {
    final cps = WaterReminderPlanner.checkpoints(fiveGlasses, day);
    expect(cps.map((c) => '${hm(c.at)}→${c.target}'), [
      '9h30→1',
      '12h00→2',
      '14h30→3',
      '17h00→4',
      '19h30→5',
    ]);
  });

  test('jamais plus de 8 rappels par jour, objectif final atteint', () {
    final cps = WaterReminderPlanner.checkpoints(
      const WaterSettings(goalGlasses: 12),
      day,
    );
    expect(cps, hasLength(WaterReminderPlanner.maxNudgesPerDay));
    expect(cps.last.target, 12);
  });

  test("un rappel dont l'objectif intermédiaire est atteint disparaît", () {
    final now = DateTime(2026, 11, 8, 14, 10);
    final today = WaterReminderPlanner.plan(
      settings: fiveGlasses,
      glassesToday: 3,
      now: now,
    ).where((r) => r.at.day == 8);

    // 14h30 (objectif 3) est déjà atteint : prochain rappel à 17h00.
    expect(today.map((r) => '${r.kind.name} ${hm(r.at)}'), [
      'nudge 17h00',
      'nudge 19h30',
      'summary 21h30',
    ]);
    expect(
      WaterReminderPlanner.nextNudge(
        settings: fiveGlasses,
        glassesToday: 3,
        now: now,
      ),
      DateTime(2026, 11, 8, 17),
    );
  });

  test('objectif atteint : plus de rappel, seulement le bilan', () {
    final today = WaterReminderPlanner.plan(
      settings: fiveGlasses,
      glassesToday: 5,
      now: DateTime(2026, 11, 8, 8),
    ).where((r) => r.at.day == 8);
    expect(today.single.kind, WaterReminderKind.summary);
    expect(today.single.glasses, 5);
  });

  test('rappels sur 7 jours, aucun si désactivés', () {
    final all = WaterReminderPlanner.plan(
      settings: fiveGlasses,
      glassesToday: 0,
      now: DateTime(2026, 11, 8, 8),
    );
    expect(all.map((r) => r.at.day).toSet(), {8, 9, 10, 11, 12, 13, 14});
    expect(all, hasLength(7 * 6));

    expect(
      WaterReminderPlanner.plan(
        settings: fiveGlasses.copyWith(remindersEnabled: false),
        glassesToday: 0,
        now: DateTime(2026, 11, 8, 8),
      ),
      isEmpty,
    );
  });

  test('journée : verres, ml, progression plafonnée', () {
    final d = WaterDay(
      day: day,
      settings: fiveGlasses,
      logs: [
        for (var i = 0; i < 6; i++)
          WaterLog(drankAt: DateTime(2026, 11, 8, 8 + i), ml: 250),
      ],
    );
    expect(d.glasses, 6);
    expect(d.mlDrunk, 1500);
    expect(d.mlGoal, 1250);
    expect(d.goalReached, isTrue);
    expect(d.remaining, 0);
    expect(d.progress, 1);
  });

  test('règles de saisie', () {
    expect(WaterRules.validate(fiveGlasses), isEmpty);
    expect(WaterRules.validate(const WaterSettings(goalGlasses: 0)), {
      WaterSettingsError.invalidGoal,
    });
    expect(
      WaterRules.validate(
        const WaterSettings(wakeMinute: 22 * 60, sleepMinute: 7 * 60),
      ),
      {WaterSettingsError.sleepBeforeWake},
    );
  });
}
