import 'dart:math' as math;

import '../entities/geo_point.dart';

/// Calculs géographiques simples.
abstract final class Geo {
  static const _earthRadiusMeters = 6371000.0;

  /// Distance à vol d'oiseau (formule de haversine), en mètres.
  static double distanceMeters(GeoPoint a, GeoPoint b) {
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLon = rad(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
  }
}
