import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/reminder_preferences.dart';
import '../../../core/time/clock.dart';
import '../data/datasources/local/medication_local_data_source.dart';
import '../data/reminders/notification_reminder_gateway.dart';
import '../data/repositories/medication_repository_impl.dart';
import '../domain/entities/day_plan.dart';
import '../domain/repositories/medication_repository.dart';
import '../domain/repositories/reminder_gateway.dart';
import '../domain/usecases/confirm_intake.dart';
import '../domain/usecases/delete_medication.dart';
import '../domain/usecases/get_medication.dart';
import '../domain/usecases/mark_intake_missed.dart';
import '../domain/usecases/reschedule_reminders.dart';
import '../domain/usecases/save_medication.dart';
import '../domain/usecases/silence_reminder.dart';
import '../domain/usecases/snooze_reminder.dart';
import '../domain/usecases/watch_day_plan.dart';
import '../domain/usecases/watch_medications.dart';
import '../presentation/mappers/reminder_texts.dart';

/// Racine de composition de la feature médicaments.
/// Typé avec l'interface : les tests peuvent fournir un faux dépôt.
final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepositoryImpl(
    MedicationLocalDataSource(ref.watch(appDatabaseProvider)),
  ),
);

/// Rappels par notifications ; le texte vient de la présentation.
final reminderGatewayProvider = Provider<ReminderGateway>(
  (ref) => NotificationReminderGateway(
    ref.watch(notificationServiceProvider),
    ReminderTexts.build,
    alarmSound: ref.watch(alarmSoundEnabledProvider),
  ),
);

final rescheduleRemindersProvider = Provider(
  (ref) => RescheduleReminders(
    ref.watch(medicationRepositoryProvider),
    ref.watch(reminderGatewayProvider),
    () => ref.read(clockProvider),
  ),
);
final silenceReminderProvider = Provider(
  (ref) => SilenceReminder(ref.watch(reminderGatewayProvider)),
);
final snoozeReminderProvider = Provider(
  (ref) => SnoozeReminder(ref.watch(reminderGatewayProvider)),
);

final watchMedicationsProvider = Provider(
  (ref) => WatchMedications(ref.watch(medicationRepositoryProvider)),
);
final getMedicationProvider = Provider(
  (ref) => GetMedication(ref.watch(medicationRepositoryProvider)),
);
final saveMedicationProvider = Provider(
  (ref) => SaveMedication(
    ref.watch(medicationRepositoryProvider),
    ref.watch(rescheduleRemindersProvider),
  ),
);
final deleteMedicationProvider = Provider(
  (ref) => DeleteMedication(
    ref.watch(medicationRepositoryProvider),
    ref.watch(rescheduleRemindersProvider),
  ),
);
final watchDayPlanProvider = Provider(
  (ref) => WatchDayPlan(ref.watch(medicationRepositoryProvider)),
);
final confirmIntakeProvider = Provider(
  (ref) => ConfirmIntake(
    ref.watch(medicationRepositoryProvider),
    ref.watch(reminderGatewayProvider),
  ),
);
final markIntakeMissedProvider = Provider(
  (ref) => MarkIntakeMissed(
    ref.watch(medicationRepositoryProvider),
    ref.watch(reminderGatewayProvider),
  ),
);

/// Prises du jour [day], recalculées quand les données changent et chaque
/// minute (horloge). Utilisé par l'écran Médicaments et par l'Accueil.
final dayPlanProvider = StreamProvider.autoDispose.family<DayPlan, DateTime>(
  (ref, day) => ref.watch(watchDayPlanProvider)(day, ref.watch(clockProvider)),
);
