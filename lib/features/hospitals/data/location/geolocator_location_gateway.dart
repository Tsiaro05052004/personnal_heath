import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/entities/location_result.dart';
import '../../domain/repositories/location_gateway.dart';

/// Position de l'utilisateur avec le GPS du téléphone (paquet geolocator).
class GeolocatorLocationGateway implements LocationGateway {
  const GeolocatorLocationGateway();

  @override
  Future<LocationProblem?> status() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationProblem.serviceDisabled;
    }
    return switch (await Geolocator.checkPermission()) {
      LocationPermission.denied => LocationProblem.permissionDenied,
      LocationPermission.deniedForever =>
        LocationProblem.permissionDeniedForever,
      _ => null,
    };
  }

  @override
  Future<LocationResult> currentPosition() => _locate(request: false);

  @override
  Future<LocationResult> requestAndLocate() => _locate(request: true);

  Future<LocationResult> _locate({required bool request}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.failed(LocationProblem.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        return const LocationResult.failed(LocationProblem.permissionDenied);
      case LocationPermission.deniedForever:
        return const LocationResult.failed(
          LocationProblem.permissionDeniedForever,
        );
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        break;
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationResult.found(GeoPoint(p.latitude, p.longitude));
    } catch (_) {
      // À l'intérieur, le GPS peut mettre longtemps : dernière position.
      final last = await Geolocator.getLastKnownPosition();
      return last == null
          ? const LocationResult.failed(LocationProblem.unavailable)
          : LocationResult.found(GeoPoint(last.latitude, last.longitude));
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
