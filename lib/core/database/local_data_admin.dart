import 'package:drift/drift.dart';

import 'app_database.dart';

/// Opérations sur l'ensemble des données de santé du téléphone (compte).
class LocalDataAdmin {
  LocalDataAdmin(this._db);

  final AppDatabase _db;

  /// Rattache à [userId] les lignes saisies avant la connexion. Les lignes
  /// d'un AUTRE compte (ne devrait pas arriver : on efface à la
  /// déconnexion) sont effacées par prudence : renvoie alors true.
  Future<bool> claimFor(String userId) => _db.transaction(() async {
    final others = await _rowsOfOtherUsers(userId);
    if (others) await _wipe();
    final userIdValue = Value<String?>(userId);
    await (_db.update(_db.medications)..where((t) => t.userId.isNull())).write(
      MedicationsCompanion(userId: userIdValue, dirty: const Value(true)),
    );
    await (_db.update(
      _db.medicationSchedules,
    )..where((t) => t.userId.isNull())).write(
      MedicationSchedulesCompanion(
        userId: userIdValue,
        dirty: const Value(true),
      ),
    );
    await (_db.update(_db.intakeLogs)..where((t) => t.userId.isNull())).write(
      IntakeLogsCompanion(userId: userIdValue, dirty: const Value(true)),
    );
    await (_db.update(
      _db.waterSettingsTable,
    )..where((t) => t.userId.isNull())).write(
      WaterSettingsTableCompanion(
        userId: userIdValue,
        dirty: const Value(true),
      ),
    );
    await (_db.update(_db.waterLogs)..where((t) => t.userId.isNull())).write(
      WaterLogsCompanion(userId: userIdValue, dirty: const Value(true)),
    );
    return others;
  });

  Future<bool> _rowsOfOtherUsers(String userId) async {
    bool other(String? owner) => owner != null && owner != userId;
    return (await _db.select(_db.medications).get()).any(
          (r) => other(r.userId),
        ) ||
        (await _db.select(_db.waterSettingsTable).get()).any(
          (r) => other(r.userId),
        ) ||
        (await _db.select(_db.waterLogs).get()).any((r) => other(r.userId));
  }

  /// Efface toutes les données de santé (déconnexion, suppression du
  /// compte). Le cache des hôpitaux, sans donnée personnelle, reste.
  Future<void> wipeHealthData() => _db.transaction(_wipe);

  Future<void> _wipe() async {
    await _db.delete(_db.intakeLogs).go();
    await _db.delete(_db.medicationSchedules).go();
    await _db.delete(_db.medications).go();
    await _db.delete(_db.waterLogs).go();
    await _db.delete(_db.waterSettingsTable).go();
  }
}
