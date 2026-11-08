import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/app/router.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/core/navigation/app_routes.dart';
import 'package:personnal_heath/features/medications/data/reminders/notification_reminder_gateway.dart';
import 'package:personnal_heath/features/medications/data/reminders/reminder_payload.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_status.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication_reminder.dart';

import '../../../helpers/fake_notification_service.dart';
import '../../../helpers/pump_app.dart';
import 'medications_screens_test.dart' show seedParacetamol, tapVisible;

/// La prise de 14h00 du Paracétamol (en attente à 14h10).
final at14h = DateTime(2026, 11, 8, 14);

Future<String> paracetamolId(AppDatabase db, WidgetTester tester) async =>
    (await tester.runAsync(() => db.select(db.medications).getSingle()))!.id;

Future<void> openAlarm(
  WidgetTester tester,
  String medicationId, {
  String? action,
}) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Navigator).first),
  );
  container
      .read(routerProvider)
      .push(AppRoutes.intakeAlarmFor(medicationId, at14h, action: action));
  await settle(tester);
}

Future<List<IntakeLogRow>> logs(AppDatabase db, WidgetTester tester) async =>
    (await tester.runAsync(() => db.select(db.intakeLogs).get()))!;

void main() {
  testWidgets('au démarrage, les rappels sont confiés au système', (
    tester,
  ) async {
    final system = FakeNotificationService();
    await pumpApp(tester, seed: seedParacetamol, notifications: system);

    final first = system.byTime
        .take(3)
        .map(
          (n) =>
              '${ReminderPayload.decode(n.payload)!.kind.name} ${n.at.hour}:${n.at.minute}',
        );
    expect(first, ['followUp 14:30', 'dose 20:0', 'followUp 20:30']);
  });

  testWidgets(
    "l'alarme sonne tant que l'écran est ouvert, se tait en le quittant",
    (tester) async {
      final system = FakeNotificationService();
      final db = await pumpApp(
        tester,
        seed: seedParacetamol,
        notifications: system,
      );
      final id = await paracetamolId(db, tester);
      final dose = NotificationReminderGateway.idFor(
        ReminderKind.dose,
        id,
        at14h,
      );

      // Android ouvre l'écran d'alarme de lui-même quand l'alarme sonne :
      // la sonnerie ne doit pas s'arrêter pour autant.
      await openAlarm(tester, id);
      expect(system.cancelled, isNot(contains(dose)));

      // Bouton retour du téléphone.
      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(system.cancelled, contains(dose));
      // Le 2e rappel de 14h30 reste prévu.
      expect(system.byTime.first.at, DateTime(2026, 11, 8, 14, 30));
    },
  );

  testWidgets("l'écran d'alarme affiche la prise (maquette 7)", (tester) async {
    final db = await pumpApp(tester, seed: seedParacetamol);
    await openAlarm(tester, await paracetamolId(db, tester));

    expect(find.text('14:00'), findsOneWidget);
    expect(find.text("C'est l'heure de votre médicament"), findsOneWidget);
    expect(find.text('Paracétamol'), findsOneWidget);
    expect(find.text('500 mg'), findsOneWidget);
    expect(find.text('Prendre 1 comprimé'), findsOneWidget);
    expect(find.text('Après le repas'), findsOneWidget);
    expect(find.textContaining('Ne doublez jamais'), findsOneWidget);
  });

  testWidgets("« J'ai pris » confirme et annule les rappels de la prise", (
    tester,
  ) async {
    final system = FakeNotificationService();
    final db = await pumpApp(
      tester,
      seed: seedParacetamol,
      notifications: system,
    );
    expect(system.byTime.first.at, DateTime(2026, 11, 8, 14, 30));

    await openAlarm(tester, await paracetamolId(db, tester));
    await tapVisible(tester, find.text("J'ai pris mon médicament"));

    final taken = (await logs(db, tester)).where((l) => l.scheduledAt == at14h);
    expect(taken.single.status, IntakeStatus.taken);
    expect(taken.single.takenAt, testNow);
    // Le 2e rappel de 14h30 a disparu.
    expect(system.byTime.first.at, DateTime(2026, 11, 8, 20));
    expect(find.text('Prise de Paracétamol confirmée.'), findsOneWidget);
  });

  testWidgets('« Plus tard » reprogramme un rappel dans 10 min', (
    tester,
  ) async {
    final system = FakeNotificationService();
    final db = await pumpApp(
      tester,
      seed: seedParacetamol,
      notifications: system,
    );

    await openAlarm(tester, await paracetamolId(db, tester));
    await tapVisible(tester, find.text('Me le rappeler dans 10 min'));

    final snooze = system.byTime.first;
    expect(snooze.at, DateTime(2026, 11, 8, 14, 20));
    expect(ReminderPayload.decode(snooze.payload)!.kind, ReminderKind.snooze);
    expect(find.text('Je vous le rappelle à 14h20.'), findsOneWidget);
    // La prise reste en attente : rien n'est enregistré.
    expect(
      (await logs(db, tester)).where((l) => l.scheduledAt == at14h),
      isEmpty,
    );
  });

  testWidgets("« Je ne l'ai pas pris » enregistre la prise non prise", (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: seedParacetamol);

    await openAlarm(tester, await paracetamolId(db, tester));
    await tapVisible(tester, find.text("Je ne l'ai pas pris"));

    final missed = (await logs(
      db,
      tester,
    )).where((l) => l.scheduledAt == at14h);
    expect(missed.single.status, IntakeStatus.missed);
  });

  testWidgets("toucher « J'ai pris » sur la notification confirme la prise", (
    tester,
  ) async {
    final system = FakeNotificationService();
    final db = await pumpApp(
      tester,
      seed: seedParacetamol,
      notifications: system,
    );
    final payload = system.byTime.first.payload;

    system.tap(payload, actionId: AppRoutes.takenAction);
    await settle(tester);

    final taken = (await logs(db, tester)).where((l) => l.scheduledAt == at14h);
    expect(taken.single.status, IntakeStatus.taken);
  });

  testWidgets("toucher la notification ouvre l'écran d'alarme", (tester) async {
    final system = FakeNotificationService();
    await pumpApp(tester, seed: seedParacetamol, notifications: system);

    system.tap(system.byTime.first.payload);
    await settle(tester);

    expect(find.text("C'est l'heure de votre médicament"), findsOneWidget);
    expect(find.text('Me le rappeler dans 10 min'), findsOneWidget);
  });

  testWidgets('une prise déjà confirmée ne propose plus de la confirmer', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: seedParacetamol);
    final id = await paracetamolId(db, tester);
    await openAlarm(tester, id);
    await tapVisible(tester, find.text("J'ai pris mon médicament"));

    await openAlarm(tester, id);

    expect(find.text('Déjà prise à 14h10'), findsOneWidget);
    expect(find.text("J'ai pris mon médicament"), findsNothing);
    expect(find.text('Fermer'), findsOneWidget);
  });

  testWidgets('médicament supprimé : message clair', (tester) async {
    await pumpApp(tester, seed: seedParacetamol);
    await openAlarm(tester, 'inexistant');

    expect(find.textContaining("n'existe plus"), findsOneWidget);
  });

  testWidgets(
    'après le premier médicament, explique puis demande les autorisations',
    (tester) async {
      final system = FakeNotificationService(granted: false);
      await pumpApp(tester, notifications: system);
      await tester.tap(find.text('Médicaments'));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Ajouter un médicament'));
      await tester.enterText(find.byType(TextField).first, 'Doliprane');
      await tapVisible(tester, find.text('Continuer'));
      await tapVisible(tester, find.text('Continuer'));
      await tapVisible(tester, find.text('Enregistrer'));

      expect(find.text('Recevoir les rappels ?'), findsOneWidget);
      await tapVisible(tester, find.text('Autoriser'));

      expect(system.permissionRequests, 1);
      expect(find.text('Doliprane'), findsOneWidget);
      // Le rappel de demain 08h00 est planifié.
      expect(
        system.byTime.map((n) => n.at),
        contains(DateTime(2026, 11, 9, 8)),
      );
    },
  );
}
