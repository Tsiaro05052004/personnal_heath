import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/preferences/preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  // Fuseau horaire + notifications (inactif sur ordinateur).
  final notifications = await LocalNotificationService.create();
  final preferences = await SharedPreferences.getInstance();
  // À venir (étape 7) : Supabase.
  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifications),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const App(),
    ),
  );
}
