import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/medications/domain/entities/intake_status.dart';
import '../../features/medications/domain/entities/meal_instruction.dart';
import 'tables/hospitals_cache.dart';
import 'tables/intake_logs.dart';
import 'tables/medication_schedules.dart';
import 'tables/medications.dart';
import 'tables/sync_columns.dart';
import 'tables/water.dart';

part 'app_database.g.dart';

/// Base locale : source de vérité de l'application (hors ligne d'abord).
@DriftDatabase(
  tables: [
    Medications,
    MedicationSchedules,
    IntakeLogs,
    WaterSettingsTable,
    WaterLogs,
    HospitalsCache,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'personnal_heath'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Instance unique de la base, fermée quand l'application s'arrête.
/// Les tests la remplacent par une base en mémoire (overrideWithValue).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
