import '../../domain/entities/geo_point.dart';
import '../../domain/entities/health_facility.dart';

/// Convertit la réponse JSON de l'API Overpass en établissements.
abstract final class OverpassMapper {
  static List<HealthFacility> facilities(Map<String, dynamic> json) {
    final elements = (json['elements'] as List?) ?? const [];
    final byId = <String, HealthFacility>{};
    for (final element in elements.whereType<Map<String, dynamic>>()) {
      final facility = _facility(element);
      if (facility != null) byId[facility.osmId] = facility;
    }
    return byId.values.toList();
  }

  static HealthFacility? _facility(Map<String, dynamic> e) {
    final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final name = (tags['name'] as String?)?.trim();
    // Sans nom, l'établissement est inutilisable pour l'utilisateur.
    if (name == null || name.isEmpty) return null;
    final type = _type(tags);
    if (type == null) return null;

    // Point : nœud (lat/lon) ou centre d'un bâtiment (center).
    final center = (e['center'] as Map?)?.cast<String, dynamic>() ?? e;
    final lat = (center['lat'] as num?)?.toDouble();
    final lon = (center['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    return HealthFacility(
      osmId: '${e['type']}/${e['id']}',
      name: name,
      type: type,
      location: GeoPoint(lat, lon),
      address: _address(tags),
      phone: _phone(tags),
    );
  }

  static FacilityType? _type(Map<String, dynamic> tags) {
    final amenity = tags['amenity'];
    final healthcare = tags['healthcare'];
    if (amenity == 'hospital' || healthcare == 'hospital') {
      final operator = '${tags['operator:type'] ?? ''}';
      return operator == 'public' || operator == 'government'
          ? FacilityType.publicHospital
          : FacilityType.hospital;
    }
    if (amenity == 'clinic' || healthcare == 'clinic') {
      return FacilityType.clinic;
    }
    if (healthcare == 'centre') return FacilityType.healthCentre;
    if (amenity == 'doctors' || healthcare == 'doctor') {
      return FacilityType.doctors;
    }
    return null;
  }

  /// « Rue X, Ampefiloha, Antananarivo » avec ce qui est disponible.
  static String? _address(Map<String, dynamic> tags) {
    final full = tags['addr:full'] as String?;
    if (full != null && full.trim().isNotEmpty) return full.trim();
    final street = [
      tags['addr:housenumber'],
      tags['addr:street'],
    ].whereType<String>().join(' ');
    final parts = [
      street,
      tags['addr:suburb'] ?? tags['addr:district'],
      tags['addr:city'],
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _phone(Map<String, dynamic> tags) {
    final raw = (tags['phone'] ?? tags['contact:phone']) as String?;
    if (raw == null || raw.trim().isEmpty) return null;
    // Plusieurs numéros séparés par « ; » : on garde le premier.
    return raw.split(';').first.trim();
  }
}
