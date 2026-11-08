import 'package:drift/drift.dart';

import '../../../../../core/database/app_database.dart';

/// Une ligne de médicament avec ses horaires actifs.
typedef MedicationWithSchedules = ({
  MedicationRow medication,
  List<MedicationScheduleRow> schedules,
});

/// Accès Drift aux tables medications, medication_schedules et intake_logs.
/// Toute écriture met `dirty = true` et `updatedAt` : la ligne sera envoyée
/// au serveur à la prochaine synchronisation (étape 7).
class MedicationLocalDataSource {
  MedicationLocalDataSource(this._db);

  final AppDatabase _db;

  /// [includeDeleted] : aussi les médicaments supprimés (historique).
  Stream<List<MedicationWithSchedules>> watchAll({
    bool includeDeleted = false,
  }) {
    final query =
        _db.select(_db.medications).join([
            leftOuterJoin(
              _db.medicationSchedules,
              _db.medicationSchedules.medicationId.equalsExp(
                    _db.medications.id,
                  ) &
                  _db.medicationSchedules.deleted.equals(false),
            ),
          ])
          ..where(
            includeDeleted
                ? const Constant(true)
                : _db.medications.deleted.equals(false),
          )
          ..orderBy([OrderingTerm.asc(_db.medications.name)]);

    return query.watch().map((rows) {
      final byId = <String, MedicationWithSchedules>{};
      for (final row in rows) {
        final med = row.readTable(_db.medications);
        final entry = byId.putIfAbsent(
          med.id,
          () => (medication: med, schedules: <MedicationScheduleRow>[]),
        );
        final schedule = row.readTableOrNull(_db.medicationSchedules);
        if (schedule != null) entry.schedules.add(schedule);
      }
      return byId.values.toList();
    });
  }

  Future<MedicationWithSchedules?> getById(String id) async {
    final med =
        await (_db.select(_db.medications)
              ..where((m) => m.id.equals(id) & m.deleted.equals(false)))
            .getSingleOrNull();
    if (med == null) return null;
    final schedules = await (_db.select(
      _db.medicationSchedules,
    )..where((s) => s.medicationId.equals(id) & s.deleted.equals(false))).get();
    return (medication: med, schedules: schedules);
  }

  /// Crée ou met à jour le médicament, puis aligne ses horaires sur
  /// [minutesOfDay] : les horaires conservés gardent leur id, les autres
  /// sont supprimés logiquement (pour propager la suppression au serveur).
  Future<String> upsert(
    MedicationsCompanion medication,
    List<int> minutesOfDay,
  ) {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final row = medication.copyWith(
        updatedAt: Value(now),
        dirty: const Value(true),
      );
      final saved = await _db
          .into(_db.medications)
          .insertReturning(
            row,
            onConflict: DoUpdate((_) => row.copyWith(id: const Value.absent())),
          );

      final existing =
          await (_db.select(_db.medicationSchedules)..where(
                (s) =>
                    s.medicationId.equals(saved.id) & s.deleted.equals(false),
              ))
              .get();
      final wanted = minutesOfDay.toSet();
      for (final schedule in existing) {
        if (!wanted.remove(schedule.minuteOfDay)) {
          await (_db.update(
            _db.medicationSchedules,
          )..where((s) => s.id.equals(schedule.id))).write(
            MedicationSchedulesCompanion(
              deleted: const Value(true),
              dirty: const Value(true),
              updatedAt: Value(now),
            ),
          );
        }
      }
      for (final minute in wanted) {
        await _db
            .into(_db.medicationSchedules)
            .insert(
              MedicationSchedulesCompanion.insert(
                medicationId: saved.id,
                minuteOfDay: minute,
                userId: medication.userId,
              ),
            );
      }
      return saved.id;
    });
  }

  /// Suppression logique du médicament seul : ses horaires restent, pour
  /// que l'historique des jours passés reste juste (le moment de la
  /// suppression est `updatedAt`).
  Future<void> softDelete(String id) =>
      (_db.update(_db.medications)..where((m) => m.id.equals(id))).write(
        MedicationsCompanion(
          deleted: const Value(true),
          dirty: const Value(true),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Stream<List<IntakeLogRow>> watchLogs(DateTime from, DateTime to) {
    return (_db.select(_db.intakeLogs)..where(
          (l) =>
              l.deleted.equals(false) &
              l.scheduledAt.isBiggerOrEqualValue(from) &
              l.scheduledAt.isSmallerThanValue(to),
        ))
        .watch();
  }

  /// Une seule prise par (médicament, heure prévue) : on remplace l'existante.
  Future<void> upsertLog(IntakeLogsCompanion log) {
    final row = log.copyWith(
      updatedAt: Value(DateTime.now().toUtc()),
      dirty: const Value(true),
      deleted: const Value(false),
    );
    return _db
        .into(_db.intakeLogs)
        .insert(
          row,
          onConflict: DoUpdate(
            (_) => row.copyWith(id: const Value.absent()),
            target: [_db.intakeLogs.medicationId, _db.intakeLogs.scheduledAt],
          ),
        );
  }
}
