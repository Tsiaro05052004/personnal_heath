import 'package:drift/drift.dart';

import 'sync_columns.dart';

/// Réglages de l'objectif d'eau (une seule ligne par utilisateur).
@DataClassName('WaterSettingsRow')
class WaterSettingsTable extends Table with SyncColumns {
  @override
  String get tableName => 'water_settings';

  IntColumn get goalGlasses => integer().withDefault(const Constant(8))();
  IntColumn get mlPerGlass => integer().withDefault(const Constant(250))();

  /// Heures de réveil et de coucher, en minutes depuis minuit : les rappels
  /// sont répartis entre les deux.
  IntColumn get wakeMinute => integer().withDefault(const Constant(7 * 60))();
  IntColumn get sleepMinute => integer().withDefault(const Constant(22 * 60))();

  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();
}

/// Un verre bu.
@DataClassName('WaterLogRow')
class WaterLogs extends Table with SyncColumns {
  DateTimeColumn get drankAt => dateTime()();
  IntColumn get ml => integer()();
}
