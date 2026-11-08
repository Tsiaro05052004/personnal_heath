import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/entities/geo_point.dart';
import '../../../domain/entities/health_facility.dart';
import '../../mappers/overpass_mapper.dart';

/// Données OpenStreetMap via l'API Overpass (service public et gratuit :
/// une requête par recherche, pas plus).
class OverpassApi {
  OverpassApi(this._client, {Uri? endpoint})
    : _endpoint =
          endpoint ?? Uri.parse('https://overpass-api.de/api/interpreter');

  final http.Client _client;
  final Uri _endpoint;

  /// En-tête demandé par les services OpenStreetMap (sans donnée
  /// personnelle).
  static const userAgent = 'MaSante/1.0 (application personnelle de sante)';

  static const timeout = Duration(seconds: 30);

  Future<List<HealthFacility>> fetch(GeoPoint center, int radiusMeters) async {
    final around =
        '(around:$radiusMeters,${center.latitude},${center.longitude})';
    final query =
        '[out:json][timeout:25];('
        'nwr["amenity"~"^(hospital|clinic|doctors)\$"]$around;'
        'nwr["healthcare"~"^(hospital|clinic|centre|doctor)\$"]$around;'
        ');out center tags;';
    final response = await _client
        .post(
          _endpoint,
          headers: {'User-Agent': userAgent},
          body: {'data': query},
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw OverpassException(response.statusCode);
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return OverpassMapper.facilities(json as Map<String, dynamic>);
  }
}

class OverpassException implements Exception {
  const OverpassException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'OverpassException($statusCode)';
}
