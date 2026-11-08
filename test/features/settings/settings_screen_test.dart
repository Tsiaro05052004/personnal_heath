import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/notifications/notification_service.dart';
import 'package:personnal_heath/features/medications/data/reminders/reminder_payload.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication_reminder.dart';

import '../../helpers/fake_hospitals.dart';
import '../../helpers/fake_notification_service.dart';
import '../../helpers/pump_app.dart';
import '../medications/presentation/medications_screens_test.dart'
    show seedParacetamol, tapVisible;

Future<void> openSettings(WidgetTester tester) =>
    tapVisible(tester, find.byTooltip('Profil et paramètres'));

List<ScheduledNotification> medicationReminders(FakeNotificationService s) =>
    s.byTime.where((n) => ReminderPayload.decode(n.payload) != null).toList();

void main() {
  testWidgets('couper l’alarme sonore replanifie avec un simple son', (
    tester,
  ) async {
    final system = FakeNotificationService();
    await pumpApp(tester, seed: seedParacetamol, notifications: system);
    expect(
      medicationReminders(system).first.channel,
      NotificationChannel.medicationAlarm,
    );

    await openSettings(tester);
    await tapVisible(tester, find.text('Alarme sonore'));

    expect(medicationReminders(system).map((n) => n.channel).toSet(), {
      NotificationChannel.medication,
    });
  });

  testWidgets('le réglage est gardé après redémarrage de l’appli', (
    tester,
  ) async {
    final system = FakeNotificationService();
    await pumpApp(
      tester,
      seed: seedParacetamol,
      notifications: system,
      preferences: {'rappels.alarme_sonore': false},
    );
    expect(
      medicationReminders(system).first.channel,
      NotificationChannel.medication,
    );
  });

  testWidgets('2e rappel après 15 min', (tester) async {
    final system = FakeNotificationService();
    await pumpApp(tester, seed: seedParacetamol, notifications: system);

    await openSettings(tester);
    await tapVisible(tester, find.text('15 min'));

    // Il est 14h10 : la prise de 14h00 a son 2e rappel à 14h15, celle de
    // 20h00 à 20h15.
    final followUps = medicationReminders(system)
        .where(
          (n) =>
              ReminderPayload.decode(n.payload)!.kind == ReminderKind.followUp,
        )
        .map((n) => n.at)
        .take(2);
    expect(followUps, [
      DateTime(2026, 11, 8, 14, 15),
      DateTime(2026, 11, 8, 20, 15),
    ]);
  });

  testWidgets('autorisations : état et demande', (tester) async {
    final system = FakeNotificationService(granted: false);
    final location = FakeLocationGateway(granted: false);
    await pumpApp(tester, notifications: system, location: location);

    await openSettings(tester);
    await scrollTo(tester, find.text('Fonctionnement en arrière-plan'));
    expect(
      find.text('Refusées : aucun rappel ne s’affichera.'),
      findsOneWidget,
    );
    expect(
      find.text('Pas encore autorisée (carte des hôpitaux).'),
      findsOneWidget,
    );

    await tapVisible(tester, find.text('Autoriser').first);
    expect(system.permissionRequests, 1);

    await tapVisible(tester, find.text('Autoriser').last);
    expect(location.requests, 1);
    expect(find.text('Autorisé'), findsNWidgets(3));
  });

  testWidgets("lien vers l'objectif d'eau", (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    await tapVisible(tester, find.text("Mon objectif d'eau"));
    expect(find.text('Combien de verres par jour ?'), findsOneWidget);
  });
}
