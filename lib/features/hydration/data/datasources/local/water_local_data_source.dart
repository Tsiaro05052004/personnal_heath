import 'package:drift/drift.dart';

import '../../../../../core/database/app_database.dart';

/// Accès Drift aux tables water_settings et water_logs. Toute écriture met
/// `dirty = true` (synchronisation, étape 7).
class WaterLocalDataSource {
  WaterLocalDataSource(this._db);

  final AppDatabase _db;

  /// La ligne de réglages (une seule par utilisateur).
  Stream<WaterSettingsRow?> watchSettings() =>
      (_db.select(_db.waterSettingsTable)
            ..where((s) => s.deleted.equals(false))
            ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)])
            ..limit(1))
          .watchSingleOrNull();

  Future<void> saveSettings(WaterSettingsTableCompanion settings) {
    return _db.transaction(() async {
      final existing =
          await (_db.select(_db.waterSettingsTable)
                ..where((s) => s.deleted.equals(false))
                ..limit(1))
              .getSingleOrNull();
      final row = settings.copyWith(
        updatedAt: Value(DateTime.now().toUtc()),
        dirty: const Value(true),
      );
      if (existing == null) {
        await _db.into(_db.waterSettingsTable).insert(row);
      } else {
        await (_db.update(
          _db.waterSettingsTable,
        )..where((s) => s.id.equals(existing.id))).write(row);
      }
    });
  }

  Stream<List<WaterLogRow>> watchLogs(DateTime from, DateTime to) =>
      (_db.select(_db.waterLogs)
            ..where(
              (l) =>
                  l.deleted.equals(false) &
                  l.drankAt.isBiggerOrEqualValue(from) &
                  l.drankAt.isSmallerThanValue(to),
            )
            ..orderBy([(l) => OrderingTerm.asc(l.drankAt)]))
          .watch();

  Future<void> addLog(WaterLogsCompanion log) =>
      _db.into(_db.waterLogs).insert(log);

  /// Suppression logique (pour propager l'annulation au serveur).
  Future<void> softDeleteLog(String id) =>
      (_db.update(_db.waterLogs)..where((l) => l.id.equals(id))).write(
        WaterLogsCompanion(
          deleted: const Value(true),
          dirty: const Value(true),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
}
