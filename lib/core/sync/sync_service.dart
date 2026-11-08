import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import 'sync_remote.dart';

/// Bilan d'une synchronisation.
class SyncReport {
  const SyncReport({required this.pulled, required this.pushed});

  /// Lignes reçues du serveur et appliquées sur le téléphone.
  final int pulled;

  /// Lignes envoyées au serveur.
  final int pushed;
}

/// Synchronise la base du téléphone (source de vérité, hors ligne d'abord)
/// avec Supabase (architecture, section 8).
///
/// 1. Récupère ce qui a changé sur le serveur depuis la dernière fois
///    (server_updated_at) et l'applique, sauf si la ligne du téléphone est
///    plus récente et pas encore envoyée : la modification la plus récente
///    gagne.
/// 2. Envoie les lignes « à synchroniser » (dirty), dans l'ordre des
///    dépendances (médicaments avant horaires et prises).
class SyncService {
  SyncService(this._db, this._remote, this._prefs);

  final AppDatabase _db;
  final SyncRemote _remote;
  final SharedPreferences _prefs;

  Future<SyncReport> sync(String userId) async {
    var pulled = 0;
    for (final table in _tables) {
      pulled += await _pull(table, userId);
    }
    var pushed = 0;
    for (final table in _tables) {
      pushed += await _push(table, userId);
    }
    return SyncReport(pulled: pulled, pushed: pushed);
  }

  /// Reste-t-il des données à envoyer ?
  Future<bool> hasUnsyncedData() async {
    for (final table in _tables) {
      if ((await table.dirty(_db)).isNotEmpty) return true;
    }
    return false;
  }

  // --------------------------------------------------------------- Récupérer

  static const _cursorPrefix = 'sync.';

  String _cursorKey(String userId, String table) =>
      '$_cursorPrefix$userId.$table';

  /// Oublie où en est la récupération. À faire quand la base locale est
  /// effacée : sinon, à la reconnexion, le téléphone croirait déjà tout
  /// avoir et ne récupérerait rien.
  Future<void> forgetCursors() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cursorPrefix));
    for (final key in keys.toList()) {
      await _prefs.remove(key);
    }
  }

  Future<int> _pull(_SyncTable table, String userId) async {
    final key = _cursorKey(userId, table.name);
    final rows = await _remote.changesSince(
      table.name,
      userId,
      _prefs.getString(key),
    );
    if (rows.isEmpty) return 0;
    var applied = 0;
    await _db.transaction(() async {
      for (final row in rows) {
        if (await table.apply(_db, row)) applied++;
      }
    });
    // Curseur = texte exact renvoyé par le serveur (pas d'arrondi).
    await _prefs.setString(key, rows.last['server_updated_at'] as String);
    return applied;
  }

  // ----------------------------------------------------------------- Envoyer

  Future<int> _push(_SyncTable table, String userId) async {
    final rows = await table.dirty(_db);
    if (rows.isEmpty) return 0;
    await _remote.upsert(table.name, [
      for (final r in rows) {...r.json, 'user_id': userId},
    ], onConflict: table.onConflict);
    // N'efface le drapeau que si la ligne n'a pas changé entre-temps.
    for (final r in rows) {
      await table.markClean(_db, r.id, r.updatedAt);
    }
    return rows.length;
  }

  static final List<_SyncTable> _tables = [
    _medications,
    _schedules,
    _intakeLogs,
    _waterSettings,
    _waterLogs,
  ];
}

// =========================================================================
// Conversions
// =========================================================================

String _ts(DateTime d) => d.toUtc().toIso8601String();
DateTime _parseTs(Object? v) => DateTime.parse(v! as String).toLocal();
DateTime? _parseTsOrNull(Object? v) => v == null ? null : _parseTs(v);

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
DateTime _parseDate(Object? v) {
  final d = DateTime.parse(v! as String);
  return DateTime(d.year, d.month, d.day);
}

DateTime? _parseDateOrNull(Object? v) => v == null ? null : _parseDate(v);

/// La base locale garde les secondes : on compare à la seconde près.
bool _newer(DateTime a, DateTime b) =>
    a.millisecondsSinceEpoch ~/ 1000 > b.millisecondsSinceEpoch ~/ 1000;

double _toDouble(Object? v) => (v! as num).toDouble();

/// Une ligne locale à envoyer.
typedef _Dirty = ({String id, DateTime updatedAt, Map<String, dynamic> json});

/// Comment synchroniser une table.
class _SyncTable {
  const _SyncTable({
    required this.name,
    required this.dirty,
    required this.apply,
    required this.markClean,
    this.onConflict,
  });

  final String name;
  final String? onConflict;
  final Future<List<_Dirty>> Function(AppDatabase db) dirty;

  /// Applique une ligne du serveur ; renvoie true si le téléphone a changé.
  final Future<bool> Function(AppDatabase db, Map<String, dynamic> row) apply;
  final Future<void> Function(AppDatabase db, String id, DateTime updatedAt)
  markClean;
}

/// Faut-il remplacer la ligne locale par celle du serveur ?
bool _remoteWins(
  ({bool dirty, DateTime updatedAt})? local,
  DateTime remoteUpdatedAt,
) => local == null || !local.dirty || !_newer(local.updatedAt, remoteUpdatedAt);

// ------------------------------------------------------------- medications

final _medications = _SyncTable(
  name: 'medications',
  dirty: (db) async => [
    for (final m in await (db.select(
      db.medications,
    )..where((t) => t.dirty)).get())
      (
        id: m.id,
        updatedAt: m.updatedAt,
        json: {
          'id': m.id,
          'name': m.name,
          'dosage': m.dosage,
          'quantity_per_intake': m.quantityPerIntake,
          'unit': m.unit,
          'meal_instruction': m.mealInstruction.name,
          'notes': m.notes,
          'start_date': _date(m.startDate),
          'end_date': m.endDate == null ? null : _date(m.endDate!),
          'active': m.active,
          'updated_at': _ts(m.updatedAt),
          'deleted': m.deleted,
        },
      ),
  ],
  apply: (db, r) async {
    final id = r['id'] as String;
    final updatedAt = _parseTs(r['updated_at']);
    final local = await (db.select(
      db.medications,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final state = local == null
        ? null
        : (dirty: local.dirty, updatedAt: local.updatedAt);
    if (!_remoteWins(state, updatedAt)) return false;
    await db
        .into(db.medications)
        .insertOnConflictUpdate(
          MedicationsCompanion.insert(
            id: Value(id),
            userId: Value(r['user_id'] as String?),
            name: r['name'] as String,
            dosage: Value(r['dosage'] as String),
            quantityPerIntake: Value(_toDouble(r['quantity_per_intake'])),
            unit: Value(r['unit'] as String),
            mealInstruction: Value(
              db.medications.mealInstruction.converter.fromSql(
                r['meal_instruction'] as String,
              ),
            ),
            notes: Value(r['notes'] as String?),
            startDate: _parseDate(r['start_date']),
            endDate: Value(_parseDateOrNull(r['end_date'])),
            active: Value(r['active'] as bool),
            updatedAt: Value(updatedAt),
            deleted: Value(r['deleted'] as bool),
            dirty: const Value(false),
          ),
        );
    return true;
  },
  markClean: (db, id, updatedAt) =>
      (db.update(db.medications)
            ..where((t) => t.id.equals(id) & t.updatedAt.equals(updatedAt)))
          .write(const MedicationsCompanion(dirty: Value(false))),
);

// ---------------------------------------------------- medication_schedules

final _schedules = _SyncTable(
  name: 'medication_schedules',
  dirty: (db) async => [
    for (final s in await (db.select(
      db.medicationSchedules,
    )..where((t) => t.dirty)).get())
      (
        id: s.id,
        updatedAt: s.updatedAt,
        json: {
          'id': s.id,
          'medication_id': s.medicationId,
          'minute_of_day': s.minuteOfDay,
          'updated_at': _ts(s.updatedAt),
          'deleted': s.deleted,
        },
      ),
  ],
  apply: (db, r) async {
    final id = r['id'] as String;
    final updatedAt = _parseTs(r['updated_at']);
    final local = await (db.select(
      db.medicationSchedules,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final state = local == null
        ? null
        : (dirty: local.dirty, updatedAt: local.updatedAt);
    if (!_remoteWins(state, updatedAt)) return false;
    await db
        .into(db.medicationSchedules)
        .insertOnConflictUpdate(
          MedicationSchedulesCompanion.insert(
            id: Value(id),
            userId: Value(r['user_id'] as String?),
            medicationId: r['medication_id'] as String,
            minuteOfDay: r['minute_of_day'] as int,
            updatedAt: Value(updatedAt),
            deleted: Value(r['deleted'] as bool),
            dirty: const Value(false),
          ),
        );
    return true;
  },
  markClean: (db, id, updatedAt) =>
      (db.update(db.medicationSchedules)
            ..where((t) => t.id.equals(id) & t.updatedAt.equals(updatedAt)))
          .write(const MedicationSchedulesCompanion(dirty: Value(false))),
);

// ------------------------------------------------------------- intake_logs

/// Clé naturelle : une seule réponse par prise prévue, même si deux
/// téléphones ont répondu (chacun avec son propre id).
final _intakeLogs = _SyncTable(
  name: 'intake_logs',
  onConflict: 'medication_id,scheduled_at',
  dirty: (db) async => [
    for (final l in await (db.select(
      db.intakeLogs,
    )..where((t) => t.dirty)).get())
      (
        id: l.id,
        updatedAt: l.updatedAt,
        json: {
          'id': l.id,
          'medication_id': l.medicationId,
          'scheduled_at': _ts(l.scheduledAt),
          'status': l.status.name,
          'taken_at': l.takenAt == null ? null : _ts(l.takenAt!),
          'quantity_taken': l.quantityTaken,
          'updated_at': _ts(l.updatedAt),
          'deleted': l.deleted,
        },
      ),
  ],
  apply: (db, r) async {
    final id = r['id'] as String;
    final medicationId = r['medication_id'] as String;
    final scheduledAt = _parseTs(r['scheduled_at']);
    final updatedAt = _parseTs(r['updated_at']);
    // Même id, ou même prise prévue (id différent : autre téléphone).
    final matches =
        await (db.select(db.intakeLogs)..where(
              (t) =>
                  t.id.equals(id) |
                  (t.medicationId.equals(medicationId) &
                      t.scheduledAt.equals(scheduledAt)),
            ))
            .get();
    final local =
        matches.where((l) => l.id == id).firstOrNull ?? matches.firstOrNull;
    final state = local == null
        ? null
        : (dirty: local.dirty, updatedAt: local.updatedAt);
    if (!_remoteWins(state, updatedAt)) return false;
    if (local != null && local.id != id) {
      // Même prise, autre id (réponse venue d'un autre téléphone).
      await (db.delete(
        db.intakeLogs,
      )..where((t) => t.id.equals(local.id))).go();
    }
    await db
        .into(db.intakeLogs)
        .insertOnConflictUpdate(
          IntakeLogsCompanion.insert(
            id: Value(id),
            userId: Value(r['user_id'] as String?),
            medicationId: medicationId,
            scheduledAt: scheduledAt,
            status: db.intakeLogs.status.converter.fromSql(
              r['status'] as String,
            ),
            takenAt: Value(_parseTsOrNull(r['taken_at'])),
            quantityTaken: Value(
              r['quantity_taken'] == null
                  ? null
                  : _toDouble(r['quantity_taken']),
            ),
            updatedAt: Value(updatedAt),
            deleted: Value(r['deleted'] as bool),
            dirty: const Value(false),
          ),
        );
    return true;
  },
  markClean: (db, id, updatedAt) =>
      (db.update(db.intakeLogs)
            ..where((t) => t.id.equals(id) & t.updatedAt.equals(updatedAt)))
          .write(const IntakeLogsCompanion(dirty: Value(false))),
);

// ---------------------------------------------------------- water_settings

/// Un seul objectif actif par compte (index unique côté serveur) : si le
/// téléphone et le serveur en ont chacun un, le plus récent gagne et
/// l'autre est supprimé. Les suppressions partent en premier.
final _waterSettings = _SyncTable(
  name: 'water_settings',
  dirty: (db) async {
    final rows =
        await (db.select(db.waterSettingsTable)
              ..where((t) => t.dirty)
              ..orderBy([(t) => OrderingTerm.desc(t.deleted)]))
            .get();
    return [
      for (final s in rows)
        (
          id: s.id,
          updatedAt: s.updatedAt,
          json: {
            'id': s.id,
            'goal_glasses': s.goalGlasses,
            'ml_per_glass': s.mlPerGlass,
            'wake_minute': s.wakeMinute,
            'sleep_minute': s.sleepMinute,
            'reminders_enabled': s.remindersEnabled,
            'updated_at': _ts(s.updatedAt),
            'deleted': s.deleted,
          },
        ),
    ];
  },
  apply: (db, r) async {
    final id = r['id'] as String;
    final updatedAt = _parseTs(r['updated_at']);
    var deleted = r['deleted'] as bool;
    var dirty = false;
    final local = await (db.select(
      db.waterSettingsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final state = local == null
        ? null
        : (dirty: local.dirty, updatedAt: local.updatedAt);
    if (!_remoteWins(state, updatedAt)) return false;

    if (!deleted) {
      final other =
          await (db.select(db.waterSettingsTable)
                ..where((t) => t.id.equals(id).not() & t.deleted.equals(false)))
              .getSingleOrNull();
      if (other != null) {
        if (_newer(other.updatedAt, updatedAt)) {
          // Celui du téléphone est plus récent : on supprime celui du
          // serveur (envoyé à la prochaine étape).
          deleted = true;
          dirty = true;
        } else {
          await (db.update(
            db.waterSettingsTable,
          )..where((t) => t.id.equals(other.id))).write(
            WaterSettingsTableCompanion(
              deleted: const Value(true),
              dirty: const Value(true),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
        }
      }
    }
    await db
        .into(db.waterSettingsTable)
        .insertOnConflictUpdate(
          WaterSettingsTableCompanion.insert(
            id: Value(id),
            userId: Value(r['user_id'] as String?),
            goalGlasses: Value(r['goal_glasses'] as int),
            mlPerGlass: Value(r['ml_per_glass'] as int),
            wakeMinute: Value(r['wake_minute'] as int),
            sleepMinute: Value(r['sleep_minute'] as int),
            remindersEnabled: Value(r['reminders_enabled'] as bool),
            updatedAt: Value(updatedAt),
            deleted: Value(deleted),
            dirty: Value(dirty),
          ),
        );
    return true;
  },
  markClean: (db, id, updatedAt) =>
      (db.update(db.waterSettingsTable)
            ..where((t) => t.id.equals(id) & t.updatedAt.equals(updatedAt)))
          .write(const WaterSettingsTableCompanion(dirty: Value(false))),
);

// -------------------------------------------------------------- water_logs

final _waterLogs = _SyncTable(
  name: 'water_logs',
  dirty: (db) async => [
    for (final l in await (db.select(
      db.waterLogs,
    )..where((t) => t.dirty)).get())
      (
        id: l.id,
        updatedAt: l.updatedAt,
        json: {
          'id': l.id,
          'drank_at': _ts(l.drankAt),
          'ml': l.ml,
          'updated_at': _ts(l.updatedAt),
          'deleted': l.deleted,
        },
      ),
  ],
  apply: (db, r) async {
    final id = r['id'] as String;
    final updatedAt = _parseTs(r['updated_at']);
    final local = await (db.select(
      db.waterLogs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final state = local == null
        ? null
        : (dirty: local.dirty, updatedAt: local.updatedAt);
    if (!_remoteWins(state, updatedAt)) return false;
    await db
        .into(db.waterLogs)
        .insertOnConflictUpdate(
          WaterLogsCompanion.insert(
            id: Value(id),
            userId: Value(r['user_id'] as String?),
            drankAt: _parseTs(r['drank_at']),
            ml: r['ml'] as int,
            updatedAt: Value(updatedAt),
            deleted: Value(r['deleted'] as bool),
            dirty: const Value(false),
          ),
        );
    return true;
  },
  markClean: (db, id, updatedAt) =>
      (db.update(db.waterLogs)
            ..where((t) => t.id.equals(id) & t.updatedAt.equals(updatedAt)))
          .write(const WaterLogsCompanion(dirty: Value(false))),
);
