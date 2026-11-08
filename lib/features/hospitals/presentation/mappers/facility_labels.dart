import '../../../../core/utils/formatters.dart';
import '../../domain/entities/health_facility.dart';

abstract final class FacilityLabels {
  static String type(FacilityType t) => switch (t) {
    FacilityType.publicHospital => 'Hôpital public',
    FacilityType.hospital => 'Hôpital',
    FacilityType.clinic => 'Clinique',
    FacilityType.healthCentre => 'Centre de santé',
    FacilityType.doctors => 'Cabinet médical',
  };

  /// « environ 350 m », « environ 1,2 km » (à vol d'oiseau).
  static String distance(double meters) {
    if (meters < 1000) {
      final rounded = (meters / 50).round() * 50;
      return 'environ ${rounded < 50 ? 50 : rounded} m';
    }
    return 'environ ${Formatters.quantity(double.parse((meters / 1000).toStringAsFixed(1)))} km';
  }

  /// « Ampefiloha, Antananarivo · environ 1,2 km »
  static String subtitle(NearbyFacility n) => [
    if (n.facility.address != null) n.facility.address!,
    if (n.distanceMeters != null) distance(n.distanceMeters!),
  ].join(' · ');
}
