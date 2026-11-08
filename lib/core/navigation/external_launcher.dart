import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre une autre application (GPS, téléphone). Remplacé dans les tests.
abstract interface class ExternalLauncher {
  /// Renvoie false si aucune application ne sait ouvrir [uri].
  Future<bool> open(Uri uri);
}

class UrlExternalLauncher implements ExternalLauncher {
  const UrlExternalLauncher();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

final externalLauncherProvider = Provider<ExternalLauncher>(
  (ref) => const UrlExternalLauncher(),
);
