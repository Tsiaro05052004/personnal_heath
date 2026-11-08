import '../../../../core/notifications/notification_service.dart';
import '../../domain/entities/water_reminder.dart';
import '../../domain/repositories/water_reminder_gateway.dart';
import 'water_reminder_payload.dart';

/// Texte d'une notification d'eau (fourni par la présentation).
typedef WaterReminderTextBuilder = ({String title, String body}) Function(
  WaterReminder,
);

/// Rappels d'eau = notifications ordinaires (canal « eau ») : pas de
/// sonnerie de réveil, pas de plein écran. On encourage, on n'insiste pas.
class NotificationWaterReminderGateway implements WaterReminderGateway {
  NotificationWaterReminderGateway(this._service, this._text);

  final NotificationService _service;
  final WaterReminderTextBuilder _text;

  static int idFor(WaterReminder r) =>
      notificationIdFor('eau|${r.kind.name}|${r.at.millisecondsSinceEpoch}');

  @override
  Future<void> replaceAll(List<WaterReminder> reminders) async {
    final wanted = {for (final r in reminders) idFor(r): r};
    final pendingHashes = <int, int>{};
    for (final p in await _service.pending()) {
      final hash = WaterReminderPayload.hashOf(p.payload);
      if (hash == null) continue; // pas un rappel d'eau
      if (wanted.containsKey(p.id)) {
        pendingHashes[p.id] = hash;
      } else {
        await _service.cancel(p.id);
      }
    }
    for (final MapEntry(key: id, value: reminder) in wanted.entries) {
      final text = _text(reminder);
      final hash = notificationIdFor('${text.title}|${text.body}');
      if (pendingHashes[id] == hash) continue;
      await _service.schedule(
        ScheduledNotification(
          id: id,
          at: reminder.at,
          title: text.title,
          body: text.body,
          payload: WaterReminderPayload.encode(contentHash: hash),
          channel: NotificationChannel.water,
        ),
      );
    }
  }
}
