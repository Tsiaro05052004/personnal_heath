import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Option « Alarme sonore » des rappels : sonnerie de réveil répétée plutôt
/// qu'un simple son de notification. Activée par défaut (choix de
/// l'utilisateur, 2026-11-08). Étape 8 : lue depuis les Paramètres.
final alarmSoundEnabledProvider = Provider<bool>((ref) => true);
