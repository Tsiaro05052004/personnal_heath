import '../entities/nearby_search.dart';
import '../repositories/facility_repository.dart';

/// Dernière liste enregistrée (sans position ni réseau).
class GetCachedFacilities {
  const GetCachedFacilities(this._repository);

  final FacilityRepository _repository;

  Future<NearbySearch?> call() => _repository.cached();
}
