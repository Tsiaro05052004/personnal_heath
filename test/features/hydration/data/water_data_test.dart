import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/core/notifications/notification_service.dart';
import 'package:personnal_heath/features/hydration/data/datasources/local/water_local_data_source.dart';
import 'package:personnal_heath/features/hydration/data/reminders/notification_water_reminder_gateway.dart';
import 'package:personnal_heath/features/hydration/data/repositories/water_repository_impl.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_log.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_reminder.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_settings.dart';

import '../../../helpers/fake_notification_service.dart';

void main() {
  group('dépôt', () {
    late AppDatabase db;
    late WaterRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = WaterRepositoryImpl(WaterLocalDataSource(db));
    });
    tearDown(() => db.close());

    test("pas d'objectif tant qu'il n'est pas défini", () async {
      expect(await repository.watchSettings().first, isNull);
    });

    test("l'objectif est une seule ligne, mise à jour", () async {
      await repository.saveSettings(const WaterSettings(goalGlasses: 5));
      await repository.saveSettings(
        const WaterSettings(goalGlasses: 6, mlPerGlass: 300),
      );

      final saved = (await repository.watchSettings().first)!;
      expect(saved.goalGlasses, 6);
      expect(saved.mlPerGlass, 300);
      expect(await db.select(db.waterSettingsTable).get(), hasLength(1));
    });

    test('verres du jour seulement, annulation logique', () async {
      for (final hour in [8, 12]) {
        await repository.addLog(
          WaterLog(drankAt: DateTime(2026, 11, 8, hour), ml: 250),
        );
      }
      await repository.addLog(
        WaterLog(drankAt: DateTime(2026, 11, 9, 8), ml: 250),
      );

      final today = await repository
          .watchLogs(DateTime(2026, 11, 8), DateTime(2026, 11, 9))
          .first;
      expect(today.map((l) => l.drankAt.hour), [8, 12]);

      await repository.deleteLog(today.last.id);
      final after = await repository
          .watchLogs(DateTime(2026, 11, 8), DateTime(2026, 11, 9))
          .first;
      expect(after, hasLength(1));
      expect(await db.select(db.waterLogs).get(), hasLength(3));
    });
  });

  group('rappels', () {
    late FakeNotificationService system;
    late NotificationWaterReminderGateway gateway;

    setUp(() {
      system = FakeNotificationService();
      gateway = NotificationWaterReminderGateway(
        system,
        (r) => (title: 'Eau', body: '${r.glasses}/${r.goal}'),
      );
    });

    WaterReminder nudge(int hour, {int glasses = 0}) => WaterReminder(
      kind: WaterReminderKind.nudge,
      at: DateTime(2026, 11, 8, hour),
      glasses: glasses,
      goal: 5,
    );

    test('simples notifications, sans sonnerie de réveil', () async {
      await gateway.replaceAll([nudge(17)]);
      final n = system.byTime.single;
      expect(n.channel, NotificationChannel.water);
      expect(n.fullScreen, isFalse);
      expect(n.actions, isEmpty);
    });

    test('remplace les rappels d’eau sans toucher aux médicaments', () async {
      await system.schedule(
        ScheduledNotification(
          id: 1,
          at: DateTime(2026, 11, 8, 20),
          title: 'Médicament',
          body: '',
          payload: '{"type":"prise"}',
        ),
      );
      await gateway.replaceAll([nudge(12), nudge(17)]);
      await gateway.replaceAll([nudge(17, glasses: 3)]);

      expect(system.byTime.map((n) => n.title), ['Eau', 'Médicament']);
      expect(system.byTime.first.body, '3/5');
    });
  });
}
