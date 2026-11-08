import 'dart:async';

import 'package:personnal_heath/core/notifications/notification_service.dart';

/// Faux système de notifications : garde en mémoire ce qui est planifié.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.granted = true});

  /// Autorisations accordées ? (false → l'appli doit les demander).
  bool granted;
  int permissionRequests = 0;

  final scheduled = <int, ScheduledNotification>{};
  final cancelled = <int>[];
  int scheduleCalls = 0;
  final _taps = StreamController<NotificationTap>.broadcast();
  NotificationTap? launch;

  /// Simule le toucher d'une notification pendant que l'appli tourne.
  void tap(String payload, {String? actionId}) =>
      _taps.add(NotificationTap(payload: payload, actionId: actionId));

  @override
  Stream<NotificationTap> get taps => _taps.stream;

  @override
  Future<NotificationTap?> launchTap() async => launch;

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    scheduleCalls++;
    scheduled[notification.id] = notification;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<List<PendingNotification>> pending() async => [
    for (final n in scheduled.values) PendingNotification(n.id, n.payload),
  ];

  @override
  Future<NotificationPermissions> permissions() async =>
      NotificationPermissions(notifications: granted, exactAlarms: granted);

  @override
  Future<NotificationPermissions> requestPermissions() async {
    permissionRequests++;
    granted = true;
    return permissions();
  }

  /// Notifications planifiées, triées par heure.
  List<ScheduledNotification> get byTime =>
      scheduled.values.toList()..sort((a, b) => a.at.compareTo(b.at));
}
