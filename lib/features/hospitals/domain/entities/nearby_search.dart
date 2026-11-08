import 'health_facility.dart';

/// Établissements autour d'une position, frais ou tirés du cache.
class NearbySearch {
  const NearbySearch({
    required this.facilities,
    required this.fetchedAt,
    required this.fromCache,
  });

  final List<HealthFacility> facilities;

  /// Date de récupération des données.
  final DateTime fetchedAt;

  /// true si le réseau était indisponible : on montre la dernière liste
  /// connue (carte utilisable hors ligne).
  final bool fromCache;
}
