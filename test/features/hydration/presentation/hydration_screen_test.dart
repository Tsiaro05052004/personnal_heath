import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/core/notifications/notification_service.dart';
import 'package:personnal_heath/features/hydration/data/datasources/local/water_local_data_source.dart';
import 'package:personnal_heath/features/hydration/data/reminders/water_reminder_payload.dart';
import 'package:personnal_heath/features/hydration/data/repositories/water_repository_impl.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_log.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_settings.dart';

import '../../../helpers/fake_notification_service.dart';
import '../../../helpers/pump_app.dart';
import '../../medications/presentation/medications_screens_test.dart'
    show tapVisible;

/// Objectif 5 verres de 250 ml, 7h–22h ; [glasses] verres bus ce matin.
Future<void> Function(AppDatabase) seedWater(int glasses) => (db) async {
  final repo = WaterRepositoryImpl(WaterLocalDataSource(db));
  await repo.saveSettings(const WaterSettings(goalGlasses: 5));
  for (var i = 0; i < glasses; i++) {
    await repo.addLog(WaterLog(drankAt: DateTime(2026, 11, 8, 8 + i), ml: 250));
  }
};

Future<void> openWaterTab(WidgetTester tester) async {
  await tester.tap(find.text('Eau'));
  await settle(tester);
}

List<ScheduledNotification> waterNotifications(FakeNotificationService s) =>
    s.byTime.where((n) => WaterReminderPayload.isWater(n.payload)).toList();

void main() {
  testWidgets('premier lancement : définir son objectif', (tester) async {
    final system = FakeNotificationService();
    await pumpApp(tester, notifications: system);
    await openWaterTab(tester);

    expect(find.text("Définissez votre objectif d'eau"), findsOneWidget);
    await tapVisible(tester, find.text('Définir mon objectif'));

    expect(find.text("Mon objectif d'eau"), findsOneWidget);
    expect(find.text('5 verres'), findsOneWidget);
    expect(find.text('soit 1 250 ml'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Plus'));
    expect(find.text('6 verres'), findsOneWidget);
    await tapVisible(tester, find.text('Enregistrer'));

    expect(find.text('Mon eau du jour'), findsOneWidget);
    expect(find.text('0 / 6'), findsOneWidget);
    // 14h10 : prochain rappel au point suivant.
    expect(find.textContaining('Prochain rappel à'), findsOneWidget);
    expect(waterNotifications(system), isNotEmpty);
  });

  testWidgets("l'écran suit la maquette 5", (tester) async {
    await pumpApp(tester, seed: seedWater(3));
    await openWaterTab(tester);

    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.text('750 ml sur 1\u202f250 ml'), findsOneWidget);
    expect(find.text("J'ai bu un verre"), findsOneWidget);
    expect(find.text('Annuler le dernier verre'), findsOneWidget);
    // 14h30 (objectif 3) est atteint : le prochain rappel est à 17h00.
    expect(find.text('Prochain rappel à 17h00'), findsOneWidget);
  });

  testWidgets('« J’ai bu un verre » compte et replanifie les rappels', (
    tester,
  ) async {
    final system = FakeNotificationService();
    await pumpApp(tester, seed: seedWater(2), notifications: system);
    await openWaterTab(tester);
    final firstToday = waterNotifications(system).first.at;
    expect(firstToday, DateTime(2026, 11, 8, 14, 30));

    await tapVisible(tester, find.text("J'ai bu un verre"));

    expect(find.text('3 / 5'), findsOneWidget);
    expect(waterNotifications(system).first.at, DateTime(2026, 11, 8, 17));
  });

  testWidgets(
    "objectif atteint : félicitations, rappels d'aujourd'hui arrêtés",
    (tester) async {
      final system = FakeNotificationService();
      await pumpApp(tester, seed: seedWater(4), notifications: system);
      await openWaterTab(tester);

      await tapVisible(tester, find.text("J'ai bu un verre"));

      expect(
        find.text("Bravo ! Objectif d'eau atteint aujourd'hui."),
        findsOneWidget,
      );
      expect(find.text('Objectif atteint, bravo !'), findsOneWidget);
      final today = waterNotifications(system)
          .where((n) => n.at.day == 8)
          .toList();
      expect(today.single.title, "Objectif d'eau atteint");
    },
  );

  testWidgets('« Annuler le dernier verre »', (tester) async {
    await pumpApp(tester, seed: seedWater(3));
    await openWaterTab(tester);

    await tapVisible(tester, find.text('Annuler le dernier verre'));

    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('Dernier verre annulé.'), findsOneWidget);
  });

  testWidgets("toucher un rappel d'eau ouvre l'onglet Eau", (tester) async {
    final system = FakeNotificationService();
    await pumpApp(tester, seed: seedWater(1), notifications: system);
    expect(find.text('Bonjour'), findsOneWidget);

    system.tap(waterNotifications(system).first.payload);
    await settle(tester);

    expect(find.text('Mon eau du jour'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
