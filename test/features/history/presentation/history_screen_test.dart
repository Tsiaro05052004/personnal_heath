import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../medications/presentation/medications_screens_test.dart'
    show tapVisible;
import '../history_fixtures.dart';

void main() {
  testWidgets("l'historique suit la maquette 8", (tester) async {
    await pumpApp(tester, seed: seedHistory);
    await tapTab(tester, 'Historique');

    expect(find.text('Cette semaine'), findsOneWidget);
    expect(find.text('Ce mois'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Prises confirmées : 5 sur 21'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Jours objectif eau : 1 sur 7'),
      findsOneWidget,
    );

    expect(find.text('Samedi'), findsOneWidget);
    expect(find.text('7 nov.'), findsOneWidget);
    expect(find.text('3 / 3 prises'), findsOneWidget);
    expect(find.text('5 / 5 verres'), findsOneWidget);
    expect(find.text('Respecté'), findsOneWidget);
    expect(
      find.text('2 / 3 prises · 1 non confirmée · 1 en retard'),
      findsOneWidget,
    );
    expect(find.text('Partiel'), findsWidgets);
  });

  testWidgets('toucher un jour en montre le détail', (tester) async {
    await pumpApp(tester, seed: seedHistory);
    await tapTab(tester, 'Historique');

    await tapVisible(tester, find.text('6 nov.'));

    expect(find.text('Vendredi 6 novembre'), findsOneWidget);
    expect(find.text('Pris à 08h05'), findsOneWidget);
    expect(find.text('Pris à 16h00 (en retard)'), findsOneWidget);
    expect(find.text('Non confirmée'), findsOneWidget);
    expect(find.text('Eau : 0 sur 5 verres'), findsOneWidget);
  });

  testWidgets('« Ce mois » couvre plus de jours', (tester) async {
    await pumpApp(tester, seed: seedHistory);
    await tapTab(tester, 'Historique');

    await tapVisible(tester, find.text('Ce mois'));

    expect(
      find.bySemanticsLabel('Prises confirmées : 5 sur 42'),
      findsOneWidget,
    );
  });

  testWidgets('premier jour : message d’attente', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Historique');

    expect(
      find.textContaining('apparaîtra ici à partir de demain'),
      findsOneWidget,
    );
  });
}
