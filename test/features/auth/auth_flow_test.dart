import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/app/shell_scaffold.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/features/auth/domain/entities/app_user.dart';
import 'package:personnal_heath/features/medications/data/reminders/reminder_payload.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/fake_notification_service.dart';
import '../../helpers/pump_app.dart';
import '../medications/presentation/medications_screens_test.dart'
    show seedParacetamol, tapVisible;

Future<void> fill(WidgetTester tester, String label, String value) async {
  final field = find.descendant(
    of: find
        .ancestor(of: find.text(label), matching: find.byType(Column))
        .first,
    matching: find.byType(TextField),
  );
  await tester.enterText(field, value);
}

int medicationReminders(FakeNotificationService s) =>
    s.byTime.where((n) => ReminderPayload.decode(n.payload) != null).length;

void main() {
  testWidgets('non connecté : l’écran de connexion (maquette 1)', (
    tester,
  ) async {
    await pumpApp(tester, auth: FakeAuthRepository());

    expect(find.text('Ma Santé'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    await scrollTo(tester, find.textContaining('vous seul pouvez'));
    expect(
      find.textContaining('vous seul pouvez les consulter'),
      findsOneWidget,
    );
    expect(find.byType(AppNavigationBar), findsNothing);
  });

  testWidgets('connexion réussie : Accueil avec le prénom', (tester) async {
    final auth = FakeAuthRepository()
      ..addAccount(FakeAuthRepository.hery, 'motdepasse');
    final remote = FakeSyncRemote();
    await pumpApp(
      tester,
      auth: auth,
      syncRemote: remote,
      seed: seedParacetamol,
    );

    await fill(tester, 'Adresse e-mail', 'Hery@Mail.com ');
    await fill(tester, 'Mot de passe', 'motdepasse');
    await tapVisible(tester, find.text('Se connecter'));

    expect(find.text('Bonjour, Hery'), findsOneWidget);
    // Les données saisies avant la connexion sont rattachées et sauvegardées.
    expect(remote.rows('medications').single['user_id'], 'user-hery');
  });

  testWidgets('mauvais mot de passe : message clair', (tester) async {
    final auth = FakeAuthRepository()
      ..addAccount(FakeAuthRepository.hery, 'motdepasse');
    await pumpApp(tester, auth: auth);

    await fill(tester, 'Adresse e-mail', 'hery@mail.com');
    await fill(tester, 'Mot de passe', 'faux');
    await tapVisible(tester, find.text('Se connecter'));

    expect(
      find.text('Adresse e-mail ou mot de passe incorrect.'),
      findsOneWidget,
    );
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('hors connexion : message clair', (tester) async {
    final auth = FakeAuthRepository()..online = false;
    await pumpApp(tester, auth: auth);

    await fill(tester, 'Adresse e-mail', 'hery@mail.com');
    await fill(tester, 'Mot de passe', 'motdepasse');
    await tapVisible(tester, find.text('Se connecter'));

    expect(find.textContaining('Pas de connexion Internet'), findsOneWidget);
  });

  testWidgets('créer un compte', (tester) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth);

    await tapVisible(tester, find.text('Créer un compte'));
    await fill(tester, 'Votre prénom', 'Hery');
    await fill(tester, 'Adresse e-mail', 'hery@mail.com');
    await fill(tester, 'Mot de passe', 'court');
    await tapVisible(tester, find.text('Créer mon compte'));
    expect(
      find.text('Le mot de passe doit contenir au moins 8 caractères.'),
      findsOneWidget,
    );

    await fill(tester, 'Mot de passe', 'motdepasse');
    await tapVisible(tester, find.text('Créer mon compte'));

    expect(find.text('Bonjour, Hery'), findsOneWidget);
  });

  testWidgets(
    'mot de passe oublié : code par e-mail puis nouveau mot de passe',
    (tester) async {
      final auth = FakeAuthRepository()
        ..addAccount(FakeAuthRepository.hery, 'ancien-mdp');
      await pumpApp(tester, auth: auth);

      await tapVisible(tester, find.text('Mot de passe oublié ?'));
      await fill(tester, 'Adresse e-mail', 'hery@mail.com');
      await tapVisible(tester, find.text('Recevoir le code'));
      expect(auth.codeSentTo, 'hery@mail.com');

      await fill(tester, 'Code reçu par e-mail', '000000');
      await fill(tester, 'Nouveau mot de passe', 'nouveau-mdp');
      await tapVisible(tester, find.text('Changer mon mot de passe'));
      expect(find.textContaining('Ce code est incorrect'), findsOneWidget);

      await fill(tester, 'Code reçu par e-mail', '123456');
      await tapVisible(tester, find.text('Changer mon mot de passe'));
      expect(find.text('Bonjour, Hery'), findsOneWidget);
    },
  );

  testWidgets('déconnexion : données effacées du téléphone, rappels arrêtés', (
    tester,
  ) async {
    final system = FakeNotificationService();
    final remote = FakeSyncRemote();
    late AppDatabase db;
    db = await pumpApp(
      tester,
      auth: FakeAuthRepository(signedIn: FakeAuthRepository.hery),
      syncRemote: remote,
      notifications: system,
      seed: (d) async {
        await seedParacetamol(d);
      },
    );
    expect(medicationReminders(system), greaterThan(0));

    await tapVisible(tester, find.byTooltip('Profil et paramètres'));
    await tapVisible(tester, find.text('Se déconnecter'));
    await tapVisible(tester, find.text('Se déconnecter').last);

    expect(find.text('Se connecter'), findsOneWidget);
    expect(medicationReminders(system), 0);
    expect(
      (await tester.runAsync(() => db.select(db.medications).get()))!,
      isEmpty,
    );
    // Sauvegardé avant d’être effacé.
    expect(remote.rows('medications'), hasLength(1));
  });

  testWidgets('supprimer le compte et toutes les données', (tester) async {
    final auth = FakeAuthRepository(signedIn: FakeAuthRepository.hery);
    final db = await pumpApp(
      tester,
      auth: auth,
      syncRemote: FakeSyncRemote(),
      seed: seedParacetamol,
    );

    await tapVisible(tester, find.byTooltip('Profil et paramètres'));
    await tapVisible(tester, find.text('Supprimer mon compte et mes données'));
    expect(find.textContaining('ne peut pas être annulée'), findsOneWidget);
    await tapVisible(tester, find.text('Supprimer définitivement'));

    expect(auth.deleted, isTrue);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(
      (await tester.runAsync(() => db.select(db.medications).get()))!,
      isEmpty,
    );
  });

  testWidgets('un autre utilisateur ne voit pas les données du précédent', (
    tester,
  ) async {
    final auth = FakeAuthRepository(signedIn: FakeAuthRepository.hery)
      ..addAccount(
        const AppUser(
          id: 'user-rasoa',
          email: 'rasoa@mail.com',
          displayName: 'Rasoa',
        ),
        'motdepasse',
      );
    await pumpApp(
      tester,
      auth: auth,
      syncRemote: FakeSyncRemote(),
      seed: seedParacetamol,
    );

    await tapVisible(tester, find.byTooltip('Profil et paramètres'));
    await tapVisible(tester, find.text('Se déconnecter'));
    await tapVisible(tester, find.text('Se déconnecter').last);
    await fill(tester, 'Adresse e-mail', 'rasoa@mail.com');
    await fill(tester, 'Mot de passe', 'motdepasse');
    await tapVisible(tester, find.text('Se connecter'));

    expect(find.text('Bonjour, Rasoa'), findsOneWidget);
    expect(find.text('Aucun médicament'), findsOneWidget);
  });
}
