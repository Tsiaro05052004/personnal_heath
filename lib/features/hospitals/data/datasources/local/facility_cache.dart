import '../../../../../core/database/app_database.dart';

/// Dernière liste d'établissements (table hospitals_cache, locale
/// uniquement) : la carte reste utile hors connexion.
class FacilityCache {
  FacilityCache(this._db);

  final AppDatabase _db;

  Future<List<HospitalRow>> readAll() => _db.select(_db.hospitalsCache).get();

  Future<void> replaceAll(List<HospitalsCacheCompanion> rows) =>
      _db.transaction(() async {
        await _db.delete(_db.hospitalsCache).go();
        await _db.batch((b) => b.insertAll(_db.hospitalsCache, rows));
      });
}
