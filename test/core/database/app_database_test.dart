import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_status.dart';
import 'package:personnal_heath/features/medications/domain/entities/meal_instruction.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'un médicament reçoit un UUID et est marqué « à synchroniser »',
    () async {
      final med = await db
          .into(db.medications)
          .insertReturning(
            MedicationsCompanion.insert(
              name: 'Paracétamol',
              dosage: const Value('500 mg'),
              quantityPerIntake: const Value(2),
              mealInstruction: const Value(MealInstruction.afterMeal),
              startDate: DateTime(2026, 11, 7),
            ),
          );

      expect(med.id, hasLength(36));
      expect(med.dirty, isTrue);
      expect(med.deleted, isFalse);
      expect(med.mealInstruction, MealInstruction.afterMeal);
    },
  );

  test(
    'une prise ne peut être enregistrée deux fois pour le même horaire',
    () async {
      final med = await db
          .into(db.medications)
          .insertReturning(
            MedicationsCompanion.insert(name: 'A', startDate: DateTime(2026)),
          );
      IntakeLogsCompanion log() => IntakeLogsCompanion.insert(
        medicationId: med.id,
        scheduledAt: DateTime(2026, 11, 7, 8),
        status: IntakeStatus.taken,
      );

      await db.into(db.intakeLogs).insert(log());
      expect(db.into(db.intakeLogs).insert(log()), throwsA(isA<Exception>()));
    },
  );

  test('un horaire doit référencer un médicament existant', () async {
    expect(
      db
          .into(db.medicationSchedules)
          .insert(
            MedicationSchedulesCompanion.insert(
              medicationId: 'inexistant',
              minuteOfDay: 480,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
