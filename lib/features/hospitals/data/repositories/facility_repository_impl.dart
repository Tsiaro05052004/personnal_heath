import '../../domain/entities/geo_point.dart';
import '../../domain/entities/nearby_search.dart';
import '../../domain/repositories/facility_repository.dart';
import '../datasources/local/facility_cache.dart';
import '../datasources/remote/overpass_api.dart';
import '../mappers/facility_cache_mapper.dart';

/// Réseau d'abord ; en cas d'échec, la dernière liste enregistrée.
class FacilityRepositoryImpl implements FacilityRepository {
  FacilityRepositoryImpl(this._remote, this._cache, this._now);

  final OverpassApi _remote;
  final FacilityCache _cache;
  final DateTime Function() _now;

  @override
  Future<NearbySearch> nearby(
    GeoPoint center, {
    required int radiusMeters,
  }) async {
    try {
      final facilities = await _remote.fetch(center, radiusMeters);
      final now = _now();
      await _cache.replaceAll([
        for (final f in facilities) FacilityCacheMapper.toRow(f, now),
      ]);
      return NearbySearch(
        facilities: facilities,
        fetchedAt: now,
        fromCache: false,
      );
    } catch (_) {
      final cached = await this.cached();
      if (cached == null) rethrow;
      return cached;
    }
  }

  @override
  Future<NearbySearch?> cached() async {
    final rows = await _cache.readAll();
    if (rows.isEmpty) return null;
    return NearbySearch(
      facilities: rows.map(FacilityCacheMapper.toEntity).toList(),
      fetchedAt: rows.first.fetchedAt,
      fromCache: true,
    );
  }
}
