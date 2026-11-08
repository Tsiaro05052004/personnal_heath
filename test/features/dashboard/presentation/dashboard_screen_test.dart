import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/database/app_database.dart';

import '../../../helpers/pump_app.dart';
import '../../hydration/presentation/hydration_screen_test.dart' show seedWater;
import '../../medications/presentation/medications_screens_test.dart'
    show seedParacetamol, tapVisible;

Future<void> seedBoth(AppDatabase db) async {
  await seedParacetamol(db);
  await seedWater(3)(db);
}

void main() {
  testWidgets("l'Accueil suit la maquette 2", (tester) async {
    await pumpApp(tester, seed: seedBoth);

    expect(find.text('Dimanche 8 novembre'), findsOneWidget);
    expect(find.text('Bonjour'), findsOneWidget);

    // Carte « Prochaine prise » : 14h00 en attente depuis 10 min (14h10).
    expect(
      find.text('Prochaine prise · en attente depuis 10 min'),
      findsOneWidget,
    );
    expect(find.text('14h00'), findsWidgets);
    expect(find.text('Paracétamol 500 mg'), findsOneWidget);
    expect(find.text('1 comprimé · après le repas'), findsOneWidget);
    expect(find.text('Confirmer la prise'), findsOneWidget);

    // Compteurs.
    expect(
      find.bySemanticsLabel('Médicaments : 1 sur 3 prises'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Eau : 3 sur 5 verres'), findsOneWidget);

    // Liste « Aujourd'hui ».
    await scrollTo(tester, find.text('À venir'));
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Tout voir'), findsOneWidget);
    expect(find.text('Pris'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
  });

  testWidgets('« Confirmer la prise » passe à la prise suivante', (
    tester,
  ) async {
    await pumpApp(tester, seed: seedBoth);

    await tapVisible(tester, find.text('Confirmer la prise'));

    expect(find.text('Prise de Paracétamol confirmée.'), findsOneWidget);
    expect(find.text('Prochaine prise · dans 5 h 50'), findsOneWidget);
    expect(find.text('20h00'), findsWidgets);
    // Trop tôt pour confirmer la prise de 20h00.
    expect(find.text('Confirmer la prise'), findsNothing);
    expect(
      find.bySemanticsLabel('Médicaments : 2 sur 3 prises'),
      findsOneWidget,
    );
  });

  testWidgets('sans médicament : invite à en ajouter un', (tester) async {
    await pumpApp(tester);

    expect(find.text('Aucun médicament'), findsOneWidget);
    expect(find.text('Définir un objectif'), findsOneWidget);
    expect(find.text("Aujourd'hui"), findsNothing);

    await tapVisible(tester, find.text('Ajouter un médicament'));
    expect(find.text('Nouveau médicament'), findsOneWidget);
  });

  testWidgets('soir : plus de prise, une non confirmée signalée', (
    tester,
  ) async {
    // 23h : la prise de 14h n'est toujours pas confirmée, celle de 20h
    // non plus (plus de 2 h) — jamais « oubliée » automatiquement.
    await pumpApp(
      tester,
      seed: seedParacetamol,
      now: DateTime(2026, 11, 8, 23),
    );

    expect(find.text("Plus de prise prévue aujourd'hui"), findsOneWidget);
    expect(find.text('2 prises n’ont pas été confirmées.'), findsOneWidget);
    await scrollTo(tester, find.text('20h00'));
    expect(find.text('Non confirmée'), findsNWidgets(2));

    await tapVisible(tester, find.text('Voir mes prises'));
    expect(find.text('Mes médicaments'), findsOneWidget);
  });

  testWidgets('les compteurs mènent aux onglets', (tester) async {
    await pumpApp(tester, seed: seedBoth);

    await tapVisible(tester, find.bySemanticsLabel('Eau : 3 sur 5 verres'));
    expect(find.text('Mon eau du jour'), findsOneWidget);
  });
}
