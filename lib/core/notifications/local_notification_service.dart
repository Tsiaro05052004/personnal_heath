import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../theme/app_colors.dart';
import 'notification_service.dart';

/// Implémentation avec flutter_local_notifications. Les notifications sont
/// planifiées par Android lui-même : elles sonnent appli fermée et sont
/// replanifiées par le plugin après un redémarrage du téléphone.
class LocalNotificationService implements NotificationService {
  LocalNotificationService._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<NotificationTap>.broadcast();

  /// Seules ces plateformes savent planifier des notifications.
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// Initialise les fuseaux horaires et le plugin. À appeler une fois dans
  /// main(). Renvoie un service inactif sur les plateformes non prises en
  /// charge (Linux de développement).
  static Future<NotificationService> create() async {
    if (!isSupported) return const DisabledNotificationService();

    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      // Fuseau inconnu : on garde UTC plutôt que de ne rien rappeler.
      debugPrint('Fuseau horaire introuvable : $e');
    }

    final service = LocalNotificationService._(
      FlutterLocalNotificationsPlugin(),
    );
    await service._plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Les autorisations sont demandées au bon moment, pas au démarrage.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final tap = _toTap(response);
        if (tap != null) service._taps.add(tap);
      },
    );
    for (final channel in NotificationChannel.values) {
      await service._android?.createNotificationChannel(
        AndroidNotificationChannel(
          channel.id,
          channel.label,
          importance: Importance.max,
          sound: channel.alarmSound ? _alarmRingtone : null,
          audioAttributesUsage: channel.alarmSound
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
        ),
      );
    }
    return service;
  }

  /// Sonnerie de réveil choisie dans les réglages du téléphone.
  static const _alarmRingtone = UriAndroidNotificationSound(
    'content://settings/system/alarm_alert',
  );

  /// Notification.FLAG_INSISTENT : le son se répète jusqu'à une réaction.
  static const _flagInsistent = 4;

  static NotificationTap? _toTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return null;
    return NotificationTap(payload: payload, actionId: response.actionId);
  }

  @override
  Stream<NotificationTap> get taps => _taps.stream;

  @override
  Future<NotificationTap?> launchTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true || response == null) {
      return null;
    }
    return _toTap(response);
  }

  @override
  Future<void> schedule(ScheduledNotification n) async {
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    await _plugin.zonedSchedule(
      id: n.id,
      scheduledDate: tz.TZDateTime.from(n.at, tz.local),
      title: n.title,
      body: n.body,
      payload: n.payload,
      // Mode « réveil » (setAlarmClock) : le seul que les surcouches comme
      // ColorOS (Realme/Oppo) ne retardent pas. En mode « exact » simple,
      // le Realme de test décalait les rappels jusqu'à 1 h. Sans
      // l'autorisation des alarmes exactes, Android peut les décaler.
      androidScheduleMode: exact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          n.channel.id,
          n.channel.label,
          importance: Importance.max,
          priority: Priority.high,
          category: n.fullScreen
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.reminder,
          fullScreenIntent: n.fullScreen,
          color: AppColors.primary,
          sound: n.channel.alarmSound ? _alarmRingtone : null,
          audioAttributesUsage: n.channel.alarmSound
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
          additionalFlags: n.channel.alarmSound
              ? Int32List.fromList([_flagInsistent])
              : null,
          // Arrête une sonnerie que personne n'entend ; le 2e rappel
          // sonnera à nouveau.
          timeoutAfter: n.channel.alarmSound
              ? alarmRingDuration.inMilliseconds
              : null,
          styleInformation: BigTextStyleInformation(n.body),
          actions: [
            for (final action in n.actions)
              AndroidNotificationAction(
                action.id,
                action.label,
                // Ouvre l'appli : l'action y est traitée (base locale).
                showsUserInterface: true,
                cancelNotification: true,
              ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<List<PendingNotification>> pending() async => [
    for (final request in await _plugin.pendingNotificationRequests())
      PendingNotification(request.id, request.payload),
  ];

  @override
  Future<NotificationPermissions> permissions() async {
    final android = _android;
    if (android != null) {
      return NotificationPermissions(
        notifications: await android.areNotificationsEnabled() ?? false,
        exactAlarms: await android.canScheduleExactNotifications() ?? false,
      );
    }
    final ios = await _ios?.checkPermissions();
    return NotificationPermissions(
      notifications: ios?.isEnabled ?? false,
      exactAlarms: true,
    );
  }

  @override
  Future<NotificationPermissions> requestPermissions() async {
    final android = _android;
    if (android != null) {
      await android.requestNotificationsPermission();
      if (await android.canScheduleExactNotifications() != true) {
        await android.requestExactAlarmsPermission();
      }
    } else {
      await _ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return permissions();
  }
}

/// Service inactif (plateformes sans notifications planifiées).
class DisabledNotificationService implements NotificationService {
  const DisabledNotificationService();

  @override
  Stream<NotificationTap> get taps => const Stream.empty();
  @override
  Future<NotificationTap?> launchTap() async => null;
  @override
  Future<void> schedule(ScheduledNotification notification) async {}
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<List<PendingNotification>> pending() async => const [];
  @override
  Future<NotificationPermissions> permissions() async =>
      const NotificationPermissions(
        notifications: false,
        exactAlarms: false,
        supported: false,
      );
  @override
  Future<NotificationPermissions> requestPermissions() => permissions();
}
