import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/time/clock.dart';
import '../data/datasources/local/water_local_data_source.dart';
import '../data/reminders/notification_water_reminder_gateway.dart';
import '../data/repositories/water_repository_impl.dart';
import '../domain/entities/water_day.dart';
import '../domain/repositories/water_reminder_gateway.dart';
import '../domain/repositories/water_repository.dart';
import '../domain/usecases/add_glass.dart';
import '../domain/usecases/get_water_settings.dart';
import '../domain/usecases/reschedule_water_reminders.dart';
import '../domain/usecases/save_water_settings.dart';
import '../domain/usecases/undo_last_glass.dart';
import '../domain/usecases/watch_water_day.dart';
import '../presentation/mappers/water_texts.dart';

/// Racine de composition de la feature hydratation.
final waterRepositoryProvider = Provider<WaterRepository>(
  (ref) =>
      WaterRepositoryImpl(WaterLocalDataSource(ref.watch(appDatabaseProvider))),
);

final waterReminderGatewayProvider = Provider<WaterReminderGateway>(
  (ref) => NotificationWaterReminderGateway(
    ref.watch(notificationServiceProvider),
    WaterTexts.reminder,
  ),
);

final rescheduleWaterRemindersProvider = Provider(
  (ref) => RescheduleWaterReminders(
    ref.watch(waterRepositoryProvider),
    ref.watch(waterReminderGatewayProvider),
    () => ref.read(clockProvider),
  ),
);

final watchWaterDayProvider = Provider(
  (ref) => WatchWaterDay(ref.watch(waterRepositoryProvider)),
);
final getWaterSettingsProvider = Provider(
  (ref) => GetWaterSettings(ref.watch(waterRepositoryProvider)),
);
final addGlassProvider = Provider(
  (ref) => AddGlass(
    ref.watch(waterRepositoryProvider),
    ref.watch(rescheduleWaterRemindersProvider),
  ),
);
final undoLastGlassProvider = Provider(
  (ref) => UndoLastGlass(
    ref.watch(waterRepositoryProvider),
    ref.watch(rescheduleWaterRemindersProvider),
  ),
);
final saveWaterSettingsProvider = Provider(
  (ref) => SaveWaterSettings(
    ref.watch(waterRepositoryProvider),
    ref.watch(rescheduleWaterRemindersProvider),
  ),
);

/// L'eau du jour [day] (null = objectif pas encore défini). Réutilisé par
/// l'Accueil et l'Historique.
final waterDayProvider = StreamProvider.autoDispose.family<WaterDay?, DateTime>(
  (ref, day) => ref.watch(watchWaterDayProvider)(day),
);
