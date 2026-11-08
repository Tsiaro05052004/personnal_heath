import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/features/hydration/data/datasources/local/water_local_data_source.dart';
import 'package:personnal_heath/features/hydration/data/repositories/water_repository_impl.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_log.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_settings.dart';
import 'package:personnal_heath/features/medications/data/datasources/local/medication_local_data_source.dart';
import 'package:personnal_heath/features/medications/data/repositories/medication_repository_impl.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_log.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_status.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';

/// Paracétamol 8h/14h/20h depuis le 25 octobre. Aujourd'hui = 8 nov.
/// - 7 nov. : 3 prises confirmées, 5 verres sur 5 → Respecté
/// - 6 nov. : 8h prise, 14h prise à 16h (en retard), 20h sans réponse
///            → Partiel (« 2 / 3 · 1 non confirmée · 1 en retard »)
/// - 5 nov. : 8h déclarée non prise
Future<void> seedHistory(AppDatabase db) async {
  final meds = MedicationRepositoryImpl(MedicationLocalDataSource(db));
  final water = WaterRepositoryImpl(WaterLocalDataSource(db));
  final id = await meds.saveMedication(
    Medication(
      id: '',
      name: 'Paracétamol',
      startDate: DateTime(2026, 10, 25),
      doseTimes: const [DoseTime(8, 0), DoseTime(14, 0), DoseTime(20, 0)],
    ),
  );
  Future<void> taken(int day, int hour, {int minute = 5, int? atHour}) =>
      meds.saveIntakeLog(
        IntakeLog(
          medicationId: id,
          scheduledAt: DateTime(2026, 11, day, hour),
          status: IntakeStatus.taken,
          takenAt: DateTime(2026, 11, day, atHour ?? hour, minute),
          quantityTaken: 1,
        ),
      );
  for (final h in [8, 14, 20]) {
    await taken(7, h);
  }
  await taken(6, 8);
  await taken(6, 14, atHour: 16, minute: 0);
  await meds.saveIntakeLog(
    IntakeLog(
      medicationId: id,
      scheduledAt: DateTime(2026, 11, 5, 8),
      status: IntakeStatus.missed,
    ),
  );

  await water.saveSettings(const WaterSettings(goalGlasses: 5));
  for (var i = 0; i < 5; i++) {
    await water.addLog(
      WaterLog(drankAt: DateTime(2026, 11, 7, 8 + i), ml: 250),
    );
  }
}
