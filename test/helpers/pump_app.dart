import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/app/shell_scaffold.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personnal_heath/app/app.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/core/navigation/external_launcher.dart';
import 'package:personnal_heath/core/preferences/preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personnal_heath/features/hospitals/di/hospitals_providers.dart';
import 'package:personnal_heath/core/notifications/notification_service.dart';
import 'package:personnal_heath/core/time/clock.dart';

import 'fake_hospitals.dart';
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
  FakeLocationGateway? location,
  FakeOverpass? overpass,
  FakeLauncher? launcher,
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = (await tester.runAsync(SharedPreferences.getInstance))!;
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
  // Écran du Realme de test : 1080 × 2400 px à densité 3, soit
  // 360 × 800 dp (un petit écran : ce qui tient ici tient partout).
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWith(() => FixedClock(now ?? testNow)),
        notificationServiceProvider.overrideWithValue(
          notifications ?? FakeNotificationService(),
        ),
        // Ni GPS, ni réseau, ni autre application dans les tests.
        locationGatewayProvider.overrideWithValue(
          location ?? FakeLocationGateway(),
        ),
        overpassApiProvider.overrideWithValue((overpass ?? FakeOverpass()).api),
        mapTilesEnabledProvider.overrideWithValue(false),
        externalLauncherProvider.overrideWithValue(launcher ?? FakeLauncher()),
        sharedPreferencesProvider.overrideWithValue(prefs),
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

/// Touche un onglet de la barre du bas (le même mot peut apparaître
/// ailleurs, ex. « Médicaments » sur l'Accueil).
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AppNavigationBar),
      matching: find.text(label),
    ),
  );
  await settle(tester);
}

/// Fait défiler la page (liste verticale principale) jusqu'à [finder] :
/// sur un écran de 800 dp, le bas des pages n'est pas encore construit.
/// Cherche d'abord vers le bas, puis vers le haut.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  final page = find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;
  try {
    await tester.scrollUntilVisible(finder, 200, scrollable: page);
  } on StateError {
    await tester.scrollUntilVisible(finder, -200, scrollable: page);
  }
  await settle(tester);
}
