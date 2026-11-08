import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/database/app_database.dart';
import '../data/datasources/local/facility_cache.dart';
import '../data/datasources/remote/overpass_api.dart';
import '../data/location/geolocator_location_gateway.dart';
import '../data/repositories/facility_repository_impl.dart';
import '../domain/repositories/facility_repository.dart';
import '../domain/repositories/location_gateway.dart';
import '../domain/usecases/find_nearby_facilities.dart';
import '../domain/usecases/get_cached_facilities.dart';

/// Racine de composition de la feature hôpitaux. Les tests remplacent
/// overpassApiProvider et locationGatewayProvider (ni réseau ni GPS).
final overpassApiProvider = Provider<OverpassApi>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OverpassApi(client);
});

final locationGatewayProvider = Provider<LocationGateway>(
  (ref) => const GeolocatorLocationGateway(),
);

final facilityRepositoryProvider = Provider<FacilityRepository>(
  (ref) => FacilityRepositoryImpl(
    ref.watch(overpassApiProvider),
    FacilityCache(ref.watch(appDatabaseProvider)),
    DateTime.now,
  ),
);

final findNearbyFacilitiesProvider = Provider(
  (ref) => FindNearbyFacilities(ref.watch(facilityRepositoryProvider)),
);
final getCachedFacilitiesProvider = Provider(
  (ref) => GetCachedFacilities(ref.watch(facilityRepositoryProvider)),
);

/// Afficher les tuiles de la carte (désactivé dans les tests : pas de
/// réseau).
final mapTilesEnabledProvider = Provider<bool>((ref) => true);
