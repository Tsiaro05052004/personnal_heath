import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/app/shell_scaffold.dart';

import '../../../helpers/fake_hospitals.dart';
import '../../../helpers/pump_app.dart';
import '../../medications/presentation/medications_screens_test.dart'
    show tapVisible;

const chu = 'CHU Joseph Ravoahangy Andrianavalona';

/// Fait défiler la fiche du bas jusqu'à [finder].
Future<void> scrollSheetTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find
        .descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await settle(tester);
}

void main() {
  testWidgets("la fiche montre l'établissement le plus proche (maquette 6)", (
    tester,
  ) async {
    await pumpApp(tester);
    await tapTab(tester, 'Hôpitaux');

    expect(find.text('Hôpital, clinique ou quartier'), findsOneWidget);
    for (final chip in ['Tous', 'Hôpitaux', 'Cliniques']) {
      expect(find.text(chip), findsWidgets);
    }
    expect(find.text('Hôpital public'), findsOneWidget);
    expect(find.text(chu), findsOneWidget);
    expect(
      find.text('Ampefiloha, Antananarivo · environ 1,2 km'),
      findsOneWidget,
    );
    expect(find.text('Itinéraire'), findsOneWidget);
    expect(find.text('Appeler'), findsOneWidget);
    expect(
      find.textContaining('Données © contributeurs OpenStreetMap'),
      findsOneWidget,
    );
    await scrollSheetTo(tester, find.text('Clinique des Sœurs'));
    expect(find.text('Clinique des Sœurs'), findsOneWidget);
  });

  testWidgets('Itinéraire et Appeler ouvrent le GPS et le composeur', (
    tester,
  ) async {
    final launcher = FakeLauncher();
    await pumpApp(tester, launcher: launcher);
    await tapTab(tester, 'Hôpitaux');

    await tapVisible(tester, find.text('Itinéraire'));
    await tapVisible(tester, find.text('Appeler'));

    expect(launcher.opened.first.scheme, 'geo');
    expect(launcher.opened.first.toString(), startsWith('geo:-18.8992,47.525'));
    expect(
      launcher.opened.last.toString(),
      'tel:+26120222797'
      '9',
    );
  });

  testWidgets('filtres et recherche', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Hôpitaux');

    await tapVisible(tester, find.text('Cliniques'));
    expect(find.text('Clinique'), findsOneWidget); // type de la fiche
    expect(find.text('Clinique des Sœurs'), findsOneWidget);
    expect(find.text(chu), findsNothing);

    await tester.tap(find.text('Tous'));
    await tester.enterText(find.byType(TextField), 'isotry');
    await settle(tester);
    expect(find.text('Centre de santé de base Isotry'), findsOneWidget);
    expect(find.text(chu), findsNothing);
  });

  testWidgets('choisir un autre établissement dans la liste', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Hôpitaux');

    await scrollSheetTo(tester, find.text('Clinique des Sœurs'));
    await tapVisible(tester, find.text('Clinique des Sœurs'));

    expect(find.text('Clinique'), findsOneWidget);
    // Le CHU passe dans la liste des autres établissements.
    await scrollSheetTo(tester, find.text(chu));
    expect(find.text(chu), findsOneWidget);
    expect(find.text('Appeler'), findsNothing); // pas de téléphone connu
  });

  testWidgets("sans autorisation : explication puis demande", (tester) async {
    final location = FakeLocationGateway(granted: false);
    await pumpApp(tester, location: location);
    await tapTab(tester, 'Hôpitaux');

    expect(find.textContaining('besoin de votre position'), findsOneWidget);
    expect(location.requests, 0);

    await tapVisible(tester, find.text('Autoriser la localisation'));

    expect(location.requests, 1);
    expect(find.text(chu), findsOneWidget);
  });

  testWidgets('hors connexion sans liste enregistrée : message clair', (
    tester,
  ) async {
    final overpass = FakeOverpass()..online = false;
    await pumpApp(tester, overpass: overpass);
    await tapTab(tester, 'Hôpitaux');

    expect(find.textContaining('Vérifiez votre connexion'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    overpass.online = true;
    await tapVisible(tester, find.text('Réessayer'));
    expect(find.text(chu), findsOneWidget);
  });

  testWidgets('hors connexion : la dernière liste reste utilisable', (
    tester,
  ) async {
    final overpass = FakeOverpass();
    await pumpApp(tester, overpass: overpass);
    await tapTab(tester, 'Hôpitaux');

    overpass.online = false;
    await tapVisible(tester, find.byTooltip('Me localiser'));

    expect(
      find.textContaining('Hors connexion : liste enregistrée'),
      findsOneWidget,
    );
    expect(find.text(chu), findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
  });
}
