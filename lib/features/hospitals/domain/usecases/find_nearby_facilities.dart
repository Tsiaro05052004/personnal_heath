import '../entities/geo_point.dart';
import '../entities/nearby_search.dart';
import '../repositories/facility_repository.dart';

/// Établissements proches : on cherche d'abord à 5 km, puis plus loin s'il
/// y en a trop peu (zones rurales).
class FindNearbyFacilities {
  const FindNearbyFacilities(this._repository);

  final FacilityRepository _repository;

  static const radii = [5000, 20000];
  static const enough = 3;

  Future<NearbySearch> call(GeoPoint center) async {
    late NearbySearch result;
    for (final radius in radii) {
      result = await _repository.nearby(center, radiusMeters: radius);
      if (result.fromCache || result.facilities.length >= enough) break;
    }
    return result;
  }
}
