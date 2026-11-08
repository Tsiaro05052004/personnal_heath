import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnal_heath/core/navigation/external_launcher.dart';
import 'package:personnal_heath/features/hospitals/data/datasources/remote/overpass_api.dart';
import 'package:personnal_heath/features/hospitals/domain/entities/geo_point.dart';
import 'package:personnal_heath/features/hospitals/domain/entities/location_result.dart';
import 'package:personnal_heath/features/hospitals/domain/repositories/location_gateway.dart';

/// Position de test, à Antananarivo.
const testPosition = GeoPoint(-18.9100, 47.5250);

/// Réponse Overpass de test : un hôpital public à ~1,2 km (maquette 6),
/// une clinique à ~2 km, un centre de santé à ~3 km, un hôpital sans nom
/// (ignoré).
final overpassSample = {
  'elements': [
    {
      'type': 'node',
      'id': 1,
      'lat': -18.8992,
      'lon': 47.5250,
      'tags': {
        'amenity': 'hospital',
        'name': 'CHU Joseph Ravoahangy Andrianavalona',
        'operator:type': 'public',
        'addr:suburb': 'Ampefiloha',
        'addr:city': 'Antananarivo',
        'phone': '+261 20 22 279 79; +261 34 00 000 00',
      },
    },
    {
      'type': 'way',
      'id': 2,
      'center': {'lat': -18.9280, 'lon': 47.5250},
      'tags': {'amenity': 'clinic', 'name': 'Clinique des Sœurs'},
    },
    {
      'type': 'node',
      'id': 3,
      'lat': -18.9100,
      'lon': 47.5535,
      'tags': {
        'healthcare': 'centre',
        'name': 'Centre de santé de base Isotry',
      },
    },
    {
      'type': 'node',
      'id': 4,
      'lat': -18.91,
      'lon': 47.52,
      'tags': {'amenity': 'hospital'},
    },
  ],
};

/// API Overpass branchée sur un faux réseau. [online] = false simule une
/// absence de connexion.
class FakeOverpass {
  bool online = true;
  int calls = 0;
  String? lastQuery;

  OverpassApi get api => OverpassApi(
    MockClient((request) async {
      calls++;
      lastQuery = request.bodyFields['data'];
      if (!online) throw http.ClientException('hors connexion');
      return http.Response.bytes(
        utf8.encode(jsonEncode(overpassSample)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
}

/// Faux GPS : [granted] = l'utilisateur a autorisé la localisation.
class FakeLocationGateway implements LocationGateway {
  FakeLocationGateway({this.granted = true, this.grantOnRequest = true});

  bool granted;
  bool grantOnRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<LocationProblem?> status() async =>
      granted ? null : LocationProblem.permissionDenied;

  @override
  Future<LocationResult> currentPosition() async => granted
      ? const LocationResult.found(testPosition)
      : const LocationResult.failed(LocationProblem.permissionDenied);

  @override
  Future<LocationResult> requestAndLocate() async {
    requests++;
    if (grantOnRequest) granted = true;
    return currentPosition();
  }

  @override
  Future<void> openAppSettings() async => settingsOpened++;

  @override
  Future<void> openLocationSettings() async => settingsOpened++;
}

/// Faux lanceur : retient les adresses ouvertes.
class FakeLauncher implements ExternalLauncher {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}
