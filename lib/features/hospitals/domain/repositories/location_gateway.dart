import '../entities/location_result.dart';

/// Position de l'utilisateur (implémentée avec le GPS du téléphone).
abstract interface class LocationGateway {
  /// Position actuelle, sans rien demander à l'utilisateur.
  Future<LocationResult> currentPosition();

  /// Demande l'autorisation (fenêtre du système) puis la position.
  Future<LocationResult> requestAndLocate();

  /// Ouvre les réglages de l'appli (autorisation refusée définitivement).
  Future<void> openAppSettings();

  /// Ouvre les réglages de localisation du téléphone.
  Future<void> openLocationSettings();
}
