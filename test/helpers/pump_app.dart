import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personnal_heath/app/app.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/core/notifications/notification_service.dart';
import 'package:personnal_heath/core/time/clock.dart';

import 'fake_notification_service.dart';

/// « Maintenant » dans les tests : dimanche 8 novembre 2026, 14h10.
final testNow = DateTime(2026, 11, 8, 14, 10);

/// Lance l'application complète sur une base en mémoire et une horloge
/// figée. Renvoie la base pour préparer des données.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  DateTime? now,
  Future<void> Function(AppDatabase db)? seed,
  FakeNotificationService? notifications,
}) async {
  await initializeDateFormatting('fr_FR');
  // closeStreamsSynchronously : sinon Drift ferme ses flux avec une minuterie
  // que le test considère « en attente » à la fin.
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  if (seed != null) await tester.runAsync(() => seed(db));
  // Écran haut comme un téléphone, pour que les listes tiennent.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWith(() => FixedClock(now ?? testNow)),
        notificationServiceProvider.overrideWithValue(
          notifications ?? FakeNotificationService(),
        ),
      ],
      child: const App(),
    ),
  );
  await settle(tester);
  return db;
}

/// Attend la fin du travail en cours, y compris celui qui ne dessine rien
/// (ex. la replanification des rappels) : les requêtes Drift ont besoin
/// d'un peu de temps réel, que pumpAndSettle (temps simulé) ne donne pas.
///
/// On alterne temps réel et images courtes (et non pumpAndSettle, qui
/// attendrait sans fin un indicateur de chargement qui tourne), puis on
/// laisse finir les animations.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}
