import '../entities/geo_point.dart';
import '../entities/nearby_search.dart';

/// Établissements de santé (OpenStreetMap), avec cache local.
abstract interface class FacilityRepository {
  /// Établissements dans un rayon de [radiusMeters] autour de [center].
  /// Hors connexion : la dernière liste enregistrée (fromCache = true).
  /// Lève une exception si rien n'est disponible.
  Future<NearbySearch> nearby(GeoPoint center, {required int radiusMeters});

  /// Dernière liste enregistrée, ou null.
  Future<NearbySearch?> cached();
}
