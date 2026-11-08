import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/features/medications/data/datasources/local/medication_local_data_source.dart';
import 'package:personnal_heath/features/medications/data/repositories/medication_repository_impl.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_log.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_status.dart';
import 'package:personnal_heath/features/medications/domain/entities/meal_instruction.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';

void main() {
  late AppDatabase db;
  late MedicationRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = MedicationRepositoryImpl(MedicationLocalDataSource(db));
  });
  tearDown(() => db.close());

  Medication paracetamol({String id = ''}) => Medication(
    id: id,
    name: 'Paracétamol',
    dosage: '500 mg',
    quantityPerIntake: 2,
    mealInstruction: MealInstruction.afterMeal,
    startDate: DateTime(2026, 11, 8),
    endDate: DateTime(2026, 11, 20),
    doseTimes: const [DoseTime(8, 0), DoseTime(14, 0), DoseTime(20, 0)],
  );

  test('enregistre puis relit un médicament et ses horaires', () async {
    final id = await repository.saveMedication(paracetamol());

    final saved = (await repository.getMedication(id))!;
    expect(saved.name, 'Paracétamol');
    expect(saved.quantityPerIntake, 2);
    expect(saved.mealInstruction, MealInstruction.afterMeal);
    expect(saved.endDate, DateTime(2026, 11, 20));
    expect(saved.doseTimes.map((t) => t.toString()), [
      '08:00',
      '14:00',
      '20:00',
    ]);

    final all = await repository.watchMedications().first;
    expect(all.single.id, id);
  });

  test('modifier les horaires garde les horaires inchangés', () async {
    final id = await repository.saveMedication(paracetamol());
    final before = await db.select(db.medicationSchedules).get();
    final kept08 = before.firstWhere((s) => s.minuteOfDay == 480).id;

    await repository.saveMedication(
      paracetamol(id: id)
          .copyWith(doseTimes: const [DoseTime(8, 0), DoseTime(21, 0)]),
    );

    final saved = (await repository.getMedication(id))!;
    expect(saved.doseTimes.map((t) => t.toString()), ['08:00', '21:00']);
    final rows = await db.select(db.medicationSchedules).get();
    expect(rows.firstWhere((s) => s.minuteOfDay == 480).id, kept08);
    // Les horaires retirés sont supprimés logiquement (pour la synchro).
    expect(rows.where((s) => s.deleted).map((s) => s.minuteOfDay), [840, 1200]);
    expect(await db.select(db.medications).get(), hasLength(1));
  });

  test('supprimer cache le médicament mais garde ses prises', () async {
    final id = await repository.saveMedication(paracetamol());
    await repository.saveIntakeLog(
      IntakeLog(
        medicationId: id,
        scheduledAt: DateTime(2026, 11, 8, 8),
        status: IntakeStatus.taken,
        takenAt: DateTime(2026, 11, 8, 8, 5),
      ),
    );

    await repository.deleteMedication(id);

    expect(await repository.watchMedications().first, isEmpty);
    expect(await repository.getMedication(id), isNull);
    expect(await db.select(db.intakeLogs).get(), hasLength(1));
  });

  test('une prise remplace celle du même horaire', () async {
    final id = await repository.saveMedication(paracetamol());
    final at = DateTime(2026, 11, 8, 14);

    await repository.saveIntakeLog(
      IntakeLog(medicationId: id, scheduledAt: at, status: IntakeStatus.missed),
    );
    await repository.saveIntakeLog(
      IntakeLog(
        medicationId: id,
        scheduledAt: at,
        status: IntakeStatus.taken,
        takenAt: DateTime(2026, 11, 8, 16, 30),
        quantityTaken: 2,
      ),
    );

    final logs = await repository
        .watchIntakeLogs(DateTime(2026, 11, 8), DateTime(2026, 11, 9))
        .first;
    expect(logs, hasLength(1));
    expect(logs.single.status, IntakeStatus.taken);
    expect(logs.single.takenAt, DateTime(2026, 11, 8, 16, 30));
  });

  test('ne renvoie que les prises de la période demandée', () async {
    final id = await repository.saveMedication(paracetamol());
    for (final day in [7, 8, 9]) {
      await repository.saveIntakeLog(
        IntakeLog(
          medicationId: id,
          scheduledAt: DateTime(2026, 11, day, 8),
          status: IntakeStatus.taken,
        ),
      );
    }

    final logs = await repository
        .watchIntakeLogs(DateTime(2026, 11, 8), DateTime(2026, 11, 9))
        .first;
    expect(logs.single.scheduledAt, DateTime(2026, 11, 8, 8));
  });
}
