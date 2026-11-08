import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_routes.dart';
import '../core/notifications/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../core/time/clock.dart';
import '../features/medications/data/reminders/reminder_payload.dart';
import '../features/medications/di/medications_providers.dart';
import 'router.dart';

/// Widget racine : thème, langue française, navigation, et branchement des
/// rappels (replanification, notifications touchées).
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  StreamSubscription<NotificationTap>? _taps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final notifications = ref.read(notificationServiceProvider);
    _taps = notifications.taps.listen(_openTap);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Appli lancée en touchant un rappel (elle était fermée).
      final launch = await notifications.launchTap();
      if (launch != null) _openTap(launch);
    });
    _reschedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taps?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'heure a pu beaucoup avancer pendant que l'appli dormait.
      ref.invalidate(clockProvider);
      _reschedule();
    }
  }

  /// Remet à jour la fenêtre glissante des rappels confiés au système.
  Future<void> _reschedule() async {
    try {
      await ref.read(rescheduleRemindersProvider)();
    } catch (e, stack) {
      debugPrint('Replanification des rappels impossible : $e\n$stack');
    }
  }

  void _openTap(NotificationTap tap) {
    final reminder = ReminderPayload.decode(tap.payload);
    if (reminder == null) return;
    ref
        .read(routerProvider)
        .push(
          AppRoutes.intakeAlarmFor(
            reminder.medicationId,
            reminder.scheduledAt,
            action: tap.actionId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ma Santé',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
