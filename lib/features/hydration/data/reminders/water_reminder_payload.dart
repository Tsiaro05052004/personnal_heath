import 'dart:convert';

/// Contenu caché des notifications d'eau : les distingue des rappels de
/// prise (type « prise ») pour que chaque feature ne gère que les siennes.
abstract final class WaterReminderPayload {
  static const _type = 'eau';

  static String encode({required int contentHash}) =>
      jsonEncode({'type': _type, 'hash': contentHash});

  /// Empreinte du contenu, ou null si ce n'est pas un rappel d'eau.
  static int? hashOf(String? payload) {
    if (payload == null) return null;
    try {
      final json = jsonDecode(payload);
      if (json is! Map || json['type'] != _type) return null;
      return json['hash'] as int? ?? 0;
    } catch (_) {
      return null;
    }
  }

  static bool isWater(String? payload) => hashOf(payload) != null;
}
