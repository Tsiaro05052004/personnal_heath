import '../../../../core/navigation/app_routes.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../domain/entities/medication_reminder.dart';
import '../../domain/repositories/reminder_gateway.dart';
import 'reminder_payload.dart';

/// Texte d'une notification de rappel (fourni par la présentation).
typedef ReminderText = ({String title, String body});
typedef ReminderTextBuilder = ReminderText Function(MedicationReminder);

/// Rappels de prise confiés aux notifications planifiées du système.
class NotificationReminderGateway implements ReminderGateway {
  NotificationReminderGateway(
    this._service,
    this._text, {
    this.alarmSound = true,
  });

  final NotificationService _service;
  final ReminderTextBuilder _text;

  /// Sonnerie de réveil répétée (option « Alarme sonore », activée par
  /// défaut) plutôt que le son de notification ordinaire.
  final bool alarmSound;

  NotificationChannel get _channel => alarmSound
      ? NotificationChannel.medicationAlarm
      : NotificationChannel.medication;

  /// À incrémenter quand la façon de planifier change (ex. passage au
  /// mode « réveil ») : force la replanification des rappels existants.
  static const scheduleVersion = 2;

  static int idFor(ReminderKind kind, String medicationId, DateTime at) =>
      notificationIdFor(
        'prise|${kind.name}|$medicationId|${at.millisecondsSinceEpoch}',
      );

  ScheduledNotification _toNotification(MedicationReminder r) {
    final text = _text(r);
    // Empreinte stable d'une exécution à l'autre (Object.hash ne l'est pas).
    final hash = notificationIdFor(
      '$scheduleVersion|${_channel.id}|${text.title}|${text.body}|'
      '${r.fireAt.millisecondsSinceEpoch}',
    );
    return ScheduledNotification(
      id: idFor(r.kind, r.medicationId, r.scheduledAt),
      at: r.fireAt,
      title: text.title,
      body: text.body,
      payload: ReminderPayload(
        kind: r.kind,
        medicationId: r.medicationId,
        scheduledAt: r.scheduledAt,
        fireAt: r.fireAt,
        contentHash: hash,
      ).encode(),
      channel: _channel,
      fullScreen: true,
      actions: const [
        NotificationButton(AppRoutes.takenAction, "J'ai pris mon médicament"),
      ],
    );
  }

  @override
  Future<void> replaceAll(
    List<MedicationReminder> reminders,
    DateTime now,
  ) async {
    final wanted = {
      for (final r in reminders)
        idFor(r.kind, r.medicationId, r.scheduledAt): r,
    };
    final pendingHashes = <int, int>{};
    for (final p in await _service.pending()) {
      final payload = ReminderPayload.decode(p.payload);
      if (payload == null || payload.kind == ReminderKind.snooze) continue;
      if (wanted.containsKey(p.id)) {
        pendingHashes[p.id] = payload.contentHash;
      } else if (payload.fireAt.isAfter(now)) {
        await _service.cancel(p.id);
      }
      // Sinon le rappel est déjà dû mais pas encore affiché (Android peut
      // le livrer avec un peu de retard) : on le laisse sonner. Les rappels
      // d'une prise confirmée sont annulés à part (cancelFor).
    }
    // Seules les notifications nouvelles ou modifiées sont replanifiées.
    for (final reminder in wanted.values) {
      final notification = _toNotification(reminder);
      final hash = ReminderPayload.decode(notification.payload)!.contentHash;
      if (pendingHashes[notification.id] != hash) {
        await _service.schedule(notification);
      }
    }
  }

  @override
  Future<void> snooze(MedicationReminder reminder) =>
      _service.schedule(_toNotification(reminder));

  @override
  Future<void> cancelFor(String medicationId, DateTime scheduledAt) async {
    for (final kind in ReminderKind.values) {
      await _service.cancel(idFor(kind, medicationId, scheduledAt));
    }
  }

  @override
  Future<void> silence(String medicationId, DateTime scheduledAt) async {
    final pending = {for (final p in await _service.pending()) p.id};
    for (final kind in ReminderKind.values) {
      final id = idFor(kind, medicationId, scheduledAt);
      // Encore en attente = pas encore affiché : on le garde.
      if (!pending.contains(id)) await _service.cancel(id);
    }
  }

  @override
  Future<ReminderPermissions> permissions() async =>
      _convert(await _service.permissions());

  @override
  Future<ReminderPermissions> requestPermissions() async =>
      _convert(await _service.requestPermissions());

  static ReminderPermissions _convert(NotificationPermissions p) =>
      ReminderPermissions(
        notifications: p.notifications,
        exactAlarms: p.exactAlarms,
        supported: p.supported,
      );
}
