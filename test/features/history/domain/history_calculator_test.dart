import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/features/history/domain/entities/history_day.dart';
import 'package:personnal_heath/features/history/domain/services/history_calculator.dart';
import 'package:personnal_heath/features/hydration/data/datasources/local/water_local_data_source.dart';
import 'package:personnal_heath/features/hydration/data/repositories/water_repository_impl.dart';
import 'package:personnal_heath/features/medications/data/datasources/local/medication_local_data_source.dart';
import 'package:personnal_heath/features/medications/data/repositories/medication_repository_impl.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';

import '../history_fixtures.dart';

void main() {
  late AppDatabase db;
  late MedicationRepositoryImpl meds;
  late WaterRepositoryImpl water;
  final now = DateTime(2026, 11, 8, 14, 10);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    meds = MedicationRepositoryImpl(MedicationLocalDataSource(db));
    water = WaterRepositoryImpl(WaterLocalDataSource(db));
    await seedHistory(db);
  });
  tearDown(() => db.close());

  Future<HistoryPeriodSummary> build(HistoryPeriod period) async {
    final range = HistoryCalculator.range(period, now);
    return HistoryCalculator.build(
      period: period,
      now: now,
      medications: await meds.watchMedications(includeDeleted: true).first,
      intakeLogs: await meds.watchIntakeLogs(range.from, range.to).first,
      waterSettings: await water.watchSettings().first,
      waterLogs: await water.watchLogs(range.from, range.to).first,
    );
  }

  test('la semaine : 7 jours avant aujourd’hui, du plus récent', () async {
    final week = await build(HistoryPeriod.week);
    expect(week.days.map((d) => d.day.day), [7, 6, 5, 4, 3, 2, 1]);
  });

  test('bilan d’un jour respecté et d’un jour partiel', () async {
    final week = await build(HistoryPeriod.week);
    final sat = week.days[0], fri = week.days[1], thu = week.days[2];

    expect(sat.confirmed, 3);
    expect(sat.summary.water!.glasses, 5);
    expect(sat.verdict, DayVerdict.respected);

    expect(fri.confirmed, 2);
    expect(fri.late, 1);
    // Sans réponse : non confirmée, JAMAIS « oubliée ».
    expect(fri.unconfirmed, 1);
    expect(fri.missed, 0);
    expect(fri.verdict, DayVerdict.partial);

    expect(thu.missed, 1);
    expect(thu.unconfirmed, 2);
  });

  test('totaux de la période', () async {
    final week = await build(HistoryPeriod.week);
    expect(week.planned, 21);
    expect(week.confirmed, 5);
    expect(week.waterDays, 7);
    expect(week.waterGoalDays, 1);
  });

  test('le mois couvre 30 jours (depuis le début du traitement)', () async {
    final month = await build(HistoryPeriod.month);
    // Traitement commencé le 25 octobre : 14 jours suivis, pas 30.
    expect(month.days, hasLength(14));
    expect(month.days.last.day, DateTime(2026, 10, 25));
  });

  test(
    'un médicament supprimé reste dans l’historique des jours d’avant',
    () async {
      final id = await meds.saveMedication(
        Medication(
          id: '',
          name: 'Amoxicilline',
          startDate: DateTime(2026, 11, 1),
          doseTimes: const [DoseTime(8, 0)],
        ),
      );
      await meds.deleteMedication(id);

      // Plus dans la liste des médicaments suivis…
      expect((await meds.watchMedications().first).map((m) => m.name), [
        'Paracétamol',
      ]);
      // … mais toujours dans les jours passés (supprimé aujourd'hui).
      final week = await build(HistoryPeriod.week);
      expect(week.days.first.planned, 4);
    },
  );
}
