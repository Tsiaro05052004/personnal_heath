import 'geo_point.dart';

/// Sorte d'établissement (étiquettes OpenStreetMap amenity / healthcare).
enum FacilityType {
  publicHospital,
  hospital,
  clinic,
  healthCentre,
  doctors;

  bool get isHospital => this == publicHospital || this == hospital;
}

/// Un établissement de santé trouvé dans OpenStreetMap. Les données
/// peuvent être incomplètes ou anciennes : l'écran le rappelle.
class HealthFacility {
  const HealthFacility({
    required this.osmId,
    required this.name,
    required this.type,
    required this.location,
    this.address,
    this.phone,
  });

  /// Identifiant OSM, ex. « node/123456 ».
  final String osmId;
  final String name;
  final FacilityType type;
  final GeoPoint location;
  final String? address;
  final String? phone;
}

/// Un établissement et sa distance à l'utilisateur.
class NearbyFacility {
  const NearbyFacility(this.facility, this.distanceMeters);

  final HealthFacility facility;

  /// null si la position de l'utilisateur est inconnue.
  final double? distanceMeters;
}
