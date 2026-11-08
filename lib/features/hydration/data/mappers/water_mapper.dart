import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/water_log.dart';
import '../../domain/entities/water_settings.dart';

/// Conversions lignes Drift ↔ entités du domaine.
abstract final class WaterMapper {
  static WaterSettings settingsToEntity(WaterSettingsRow row) => WaterSettings(
    goalGlasses: row.goalGlasses,
    mlPerGlass: row.mlPerGlass,
    wakeMinute: row.wakeMinute,
    sleepMinute: row.sleepMinute,
    remindersEnabled: row.remindersEnabled,
  );

  static WaterSettingsTableCompanion settingsToCompanion(WaterSettings s) =>
      WaterSettingsTableCompanion(
        goalGlasses: Value(s.goalGlasses),
        mlPerGlass: Value(s.mlPerGlass),
        wakeMinute: Value(s.wakeMinute),
        sleepMinute: Value(s.sleepMinute),
        remindersEnabled: Value(s.remindersEnabled),
      );

  static WaterLog logToEntity(WaterLogRow row) =>
      WaterLog(id: row.id, drankAt: row.drankAt, ml: row.ml);

  static WaterLogsCompanion logToCompanion(WaterLog log) =>
      WaterLogsCompanion.insert(drankAt: log.drankAt, ml: log.ml);
}
