import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/features/medications/data/datasources/local/medication_local_data_source.dart';
import 'package:personnal_heath/features/medications/data/repositories/medication_repository_impl.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_log.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_status.dart';
import 'package:personnal_heath/features/medications/domain/entities/meal_instruction.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';

import '../../../helpers/pump_app.dart';

/// Paracétamol 500 mg à 08h, 14h et 20h ; la prise de 08h a été confirmée
/// à 08h05. « Maintenant » = 14h10 (voir testNow).
Future<void> seedParacetamol(AppDatabase db) async {
  final repository = MedicationRepositoryImpl(MedicationLocalDataSource(db));
  final id = await repository.saveMedication(
    Medication(
      id: '',
      name: 'Paracétamol',
      dosage: '500 mg',
      mealInstruction: MealInstruction.afterMeal,
      startDate: DateTime(2026, 11, 1),
      doseTimes: const [DoseTime(8, 0), DoseTime(14, 0), DoseTime(20, 0)],
    ),
  );
  await repository.saveIntakeLog(
    IntakeLog(
      medicationId: id,
      scheduledAt: DateTime(2026, 11, 8, 8),
      status: IntakeStatus.taken,
      takenAt: DateTime(2026, 11, 8, 8, 5),
      quantityTaken: 1,
    ),
  );
}

Future<void> openMedicationsTab(WidgetTester tester) async {
  await tester.tap(find.text('Médicaments'));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche les prises du jour avec leur état', (tester) async {
    await pumpApp(tester, seed: seedParacetamol);
    await openMedicationsTab(tester);

    expect(find.text("1 prise confirmée sur 3 aujourd'hui"), findsOneWidget);
    expect(find.text('Paracétamol 500 mg'), findsOneWidget);
    expect(find.text('1 comprimé · après le repas'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Pris à 08h05'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
  });

  testWidgets("« Confirmer » enregistre l'heure réelle", (tester) async {
    await pumpApp(tester, seed: seedParacetamol);
    await openMedicationsTab(tester);

    await tapVisible(tester, find.text('Confirmer'));

    expect(find.text('Pris à 14h10'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('En attente'), findsNothing);
  });

  testWidgets("« Je ne l'ai pas pris » ne propose jamais de rattrapage", (
    tester,
  ) async {
    await pumpApp(tester, seed: seedParacetamol);
    await openMedicationsTab(tester);

    await tapVisible(tester, find.text('En attente'));
    expect(find.textContaining('Ne doublez jamais une dose'), findsOneWidget);
    await tapVisible(tester, find.text("Je ne l'ai pas pris"));

    expect(find.text('Non pris'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('une prise future ne peut pas encore être confirmée', (
    tester,
  ) async {
    await pumpApp(tester, seed: seedParacetamol);
    await openMedicationsTab(tester);

    await tapVisible(tester, find.text('À venir'));

    expect(find.text("J'ai pris mon médicament"), findsNothing);
    expect(find.textContaining('à partir de 19h30'), findsOneWidget);
  });

  testWidgets('ajoute un médicament en 3 étapes', (tester) async {
    await pumpApp(tester);
    await openMedicationsTab(tester);
    expect(find.text("Aucune prise prévue aujourd'hui."), findsOneWidget);

    await tapVisible(tester, find.text('Ajouter un médicament'));
    expect(find.text('Étape 1 sur 3 · Médicament'), findsOneWidget);

    // Le nom est obligatoire.
    await tapVisible(tester, find.text('Continuer'));
    expect(find.text('Écrivez le nom du médicament.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Doliprane');
    await tester.enterText(find.byType(TextField).at(1), '1 g');
    await tapVisible(tester, find.text('Continuer'));

    expect(find.text('Étape 2 sur 3 · Horaires'), findsOneWidget);
    expect(find.text('Doliprane · 1 g'), findsOneWidget);
    await tapVisible(tester, find.text('2×'));
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Plus'));
    expect(find.text('1,5 comprimé'), findsOneWidget);
    await tapVisible(tester, find.text('Continuer'));

    expect(find.text('Étape 3 sur 3 · Durée et consignes'), findsOneWidget);
    await tapVisible(tester, find.text('Après le repas'));
    await tapVisible(tester, find.text('Enregistrer'));

    expect(find.text('Mes médicaments'), findsOneWidget);
    expect(find.text('Doliprane 1 g'), findsOneWidget);
    expect(find.text('1,5 comprimé · après le repas'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
  });

  testWidgets('modifie puis supprime un médicament', (tester) async {
    await pumpApp(tester, seed: seedParacetamol);
    await openMedicationsTab(tester);

    await tapVisible(tester, find.text('Paracétamol 500 mg'));
    expect(find.text('Modifier le médicament'), findsOneWidget);
    expect(find.text('Paracétamol'), findsOneWidget); // champ pré-rempli

    await tapVisible(tester, find.byTooltip('Supprimer ce médicament'));
    await tapVisible(tester, find.text('Supprimer'));

    expect(find.text('Paracétamol 500 mg'), findsNothing);
    expect(find.text("Aucune prise prévue aujourd'hui."), findsOneWidget);
  });
}
