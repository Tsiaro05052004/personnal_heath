import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/app/app.dart';
import 'package:personnal_heath/core/database/app_database.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("s'ouvre sur l'accueil avec les 5 onglets", (tester) async {
    await pumpApp(tester);

    expect(find.text("Aujourd'hui"), findsOneWidget);
    for (final label in [
      'Accueil',
      'Médicaments',
      'Eau',
      'Carte',
      'Historique',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('la barre du bas change de page', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Médicaments'));
    await tester.pumpAndSettle();
    expect(find.text('Mes médicaments'), findsOneWidget);

    await tester.tap(find.text('Eau'));
    await tester.pumpAndSettle();
    expect(find.text('Hydratation'), findsOneWidget);
  });

  testWidgets("l'icône ⚙ ouvre les Paramètres", (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
