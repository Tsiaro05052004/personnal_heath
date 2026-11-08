import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Adresse et clé PUBLIQUE du projet Supabase, passées à la compilation :
///   flutter run --dart-define-from-file=supabase.json
/// (supabase.json n'est pas dans git ; modèle : supabase.example.json).
/// Sans elles, l'appli fonctionne sans compte (tests, ordinateur).
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static Future<void> initialize() =>
      Supabase.initialize(url: url, publishableKey: publishableKey);
}

/// Client Supabase, ou null si l'appli tourne sans serveur.
final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => SupabaseConfig.isConfigured ? Supabase.instance.client : null,
);
