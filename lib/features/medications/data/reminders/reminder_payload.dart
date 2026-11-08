import 'dart:convert';

import '../../domain/entities/medication_reminder.dart';

/// Contenu caché d'une notification de rappel de prise : permet de savoir,
/// quand l'utilisateur la touche, de quelle prise il s'agit.
class ReminderPayload {
  const ReminderPayload({
    required this.kind,
    required this.medicationId,
    required this.scheduledAt,
    required this.fireAt,
    this.contentHash = 0,
  });

  final ReminderKind kind;
  final String medicationId;
  final DateTime scheduledAt;

  /// Heure à laquelle le rappel doit sonner.
  final DateTime fireAt;

  /// Empreinte du texte et de l'heure : si elle change (médicament
  /// renommé…), la notification est replanifiée.
  final int contentHash;

  static const _type = 'prise';

  String encode() => jsonEncode({
    'type': _type,
    'kind': kind.name,
    'med': medicationId,
    'at': scheduledAt.millisecondsSinceEpoch,
    'fire': fireAt.millisecondsSinceEpoch,
    'hash': contentHash,
  });

  /// Null si [payload] n'est pas un rappel de prise (ex. rappel d'eau).
  static ReminderPayload? decode(String? payload) {
    if (payload == null) return null;
    try {
      final json = jsonDecode(payload);
      if (json is! Map || json['type'] != _type) return null;
      return ReminderPayload(
        kind: ReminderKind.values.byName(json['kind'] as String),
        medicationId: json['med'] as String,
        scheduledAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
        fireAt: DateTime.fromMillisecondsSinceEpoch(
          json['fire'] as int? ?? json['at'] as int,
        ),
        contentHash: json['hash'] as int? ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
