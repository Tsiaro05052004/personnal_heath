import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets("s'ouvre sur l'accueil avec les 5 onglets", (tester) async {
    await pumpApp(tester);

    expect(find.text('Bonjour'), findsOneWidget);
    for (final label in [
      'Accueil',
      'Médicaments',
      'Eau',
      'Hôpitaux',
      'Historique',
    ]) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('la barre du bas change de page', (tester) async {
    await pumpApp(tester);

    await tapTab(tester, 'Médicaments');
    expect(find.text('Mes médicaments'), findsOneWidget);

    await tapTab(tester, 'Eau');
    expect(find.text('Mon eau du jour'), findsOneWidget);
  });

  testWidgets("le bouton profil de l'accueil ouvre les Paramètres", (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Profil et paramètres'));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
