import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglages propres à ce téléphone (non synchronisés). Initialisé dans
/// main() ; les tests utilisent SharedPreferences.setMockInitialValues.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences non initialisé'),
);
