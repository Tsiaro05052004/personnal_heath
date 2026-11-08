import 'geo_point.dart';

/// Pourquoi la position n'est pas disponible.
enum LocationProblem {
  /// L'autorisation n'a pas encore été accordée (on peut la demander).
  permissionDenied,

  /// Refusée définitivement : il faut passer par les réglages.
  permissionDeniedForever,

  /// La localisation du téléphone est désactivée.
  serviceDisabled,

  /// Position introuvable pour l'instant (intérieur, délai dépassé…).
  unavailable,
}

/// Résultat d'une demande de position.
class LocationResult {
  const LocationResult.found(GeoPoint this.position) : problem = null;
  const LocationResult.failed(LocationProblem this.problem) : position = null;

  final GeoPoint? position;
  final LocationProblem? problem;
}
