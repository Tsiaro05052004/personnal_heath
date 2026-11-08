import '../entities/geo_point.dart';
import '../entities/health_facility.dart';
import 'geo.dart';

/// Filtres de la carte (maquette 6).
enum FacilityFilter {
  all,
  hospitals,

  /// Cliniques, centres de santé et cabinets médicaux.
  clinics;

  bool accepts(FacilityType type) => switch (this) {
    FacilityFilter.all => true,
    FacilityFilter.hospitals => type.isHospital,
    FacilityFilter.clinics => !type.isHospital,
  };
}

/// Filtrage et tri des établissements.
abstract final class FacilitySearch {
  /// Établissements correspondant au filtre et à la recherche (nom ou
  /// adresse, sans tenir compte des majuscules ni des accents), du plus
  /// proche au plus lointain.
  static List<NearbyFacility> apply({
    required List<HealthFacility> facilities,
    required GeoPoint? from,
    FacilityFilter filter = FacilityFilter.all,
    String query = '',
  }) {
    final words = normalize(query)
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final result = [
      for (final f in facilities)
        if (filter.accepts(f.type) && _matches(f, words))
          NearbyFacility(
            f,
            from == null ? null : Geo.distanceMeters(from, f.location),
          ),
    ];
    result.sort((a, b) {
      final da = a.distanceMeters, db = b.distanceMeters;
      if (da == null || db == null) {
        return a.facility.name.compareTo(b.facility.name);
      }
      return da.compareTo(db);
    });
    return result;
  }

  static bool _matches(HealthFacility f, List<String> words) {
    if (words.isEmpty) return true;
    final haystack = normalize('${f.name} ${f.address ?? ''}');
    return words.every(haystack.contains);
  }

  /// Minuscules, sans accents, espaces simples.
  static String normalize(String s) {
    const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyy';
    final lower = s.toLowerCase().replaceAll('œ', 'oe').replaceAll('æ', 'ae');
    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buffer.write(i < 0 ? ch : to[i]);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
