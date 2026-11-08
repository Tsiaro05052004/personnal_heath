import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/core/database/local_data_admin.dart';
import 'package:personnal_heath/core/sync/sync_coordinator.dart';
import 'package:personnal_heath/core/sync/sync_service.dart';
import 'package:personnal_heath/features/auth/data/session_data_impl.dart';
import 'package:personnal_heath/features/hydration/data/datasources/local/water_local_data_source.dart';
import 'package:personnal_heath/features/hydration/data/repositories/water_repository_impl.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_log.dart';
import 'package:personnal_heath/features/hydration/domain/entities/water_settings.dart';
import 'package:personnal_heath/features/medications/data/datasources/local/medication_local_data_source.dart';
import 'package:personnal_heath/features/medications/data/repositories/medication_repository_impl.dart';
import 'package:personnal_heath/features/medications/domain/entities/dose_time.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_log.dart';
import 'package:personnal_heath/features/medications/domain/entities/intake_status.dart';
import 'package:personnal_heath/features/medications/domain/entities/meal_instruction.dart';
import 'package:personnal_heath/features/medications/domain/entities/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_backend.dart';

const user = 'user-hery';

/// Un « téléphone » : sa base, ses dépôts, sa synchro vers [remote].
class Phone {
  Phone(FakeSyncRemote remote, SharedPreferences prefs)
    : db = AppDatabase(NativeDatabase.memory()) {
    meds = MedicationRepositoryImpl(MedicationLocalDataSource(db));
    water = WaterRepositoryImpl(WaterLocalDataSource(db));
    sync = SyncService(db, remote, prefs);
    admin = LocalDataAdmin(db);
  }

  final AppDatabase db;
  late final MedicationRepositoryImpl meds;
  late final WaterRepositoryImpl water;
  late final SyncService sync;
  late final LocalDataAdmin admin;

  Future<String> addParacetamol() => meds.saveMedication(
    Medication(
      id: '',
      name: 'Paracétamol',
      dosage: '500 mg',
      quantityPerIntake: 2,
      mealInstruction: MealInstruction.afterMeal,
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 30),
      doseTimes: const [DoseTime(8, 0), DoseTime(20, 0)],
    ),
  );
}

void main() {
  late FakeSyncRemote remote;
  late Phone a;
  late Phone b;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    remote = FakeSyncRemote();
    // Chaque téléphone a ses propres préférences (curseurs de synchro).
    a = Phone(remote, prefs);
    SharedPreferences.setMockInitialValues({});
    b = Phone(remote, await SharedPreferences.getInstance());
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test(
    'envoie les données, rattachées au compte, et les marque envoyées',
    () async {
      final id = await a.addParacetamol();
      await a.admin.claimFor(user);

      final report = await a.sync.sync(user);

      expect(report.pushed, 1 + 2); // le médicament et ses 2 horaires
      final med = remote.rows('medications').single;
      expect(med['id'], id);
      expect(med['user_id'], user);
      expect(med['start_date'], '2026-11-01');
      expect(med['meal_instruction'], 'afterMeal');
      expect(remote.rows('medication_schedules'), hasLength(2));
      expect(await a.sync.hasUnsyncedData(), isFalse);
    },
  );

  test('un deuxième téléphone retrouve tout (même compte)', () async {
    final id = await a.addParacetamol();
    await a.meds.saveIntakeLog(
      IntakeLog(
        medicationId: id,
        scheduledAt: DateTime(2026, 11, 8, 8),
        status: IntakeStatus.taken,
        takenAt: DateTime(2026, 11, 8, 8, 5),
        quantityTaken: 2,
      ),
    );
    await a.water.saveSettings(const WaterSettings(goalGlasses: 6));
    await a.water.addLog(WaterLog(drankAt: DateTime(2026, 11, 8, 9), ml: 250));
    await a.admin.claimFor(user);
    await a.sync.sync(user);

    final report = await b.sync.sync(user);

    expect(report.pulled, greaterThan(0));
    final med = (await b.meds.watchMedications().first).single;
    expect(med.name, 'Paracétamol');
    expect(med.quantityPerIntake, 2);
    expect(med.endDate, DateTime(2026, 11, 30));
    expect(med.doseTimes.map((t) => t.toString()), ['08:00', '20:00']);
    final logs = await b.meds
        .watchIntakeLogs(DateTime(2026, 11, 8), DateTime(2026, 11, 9))
        .first;
    expect(logs.single.takenAt, DateTime(2026, 11, 8, 8, 5));
    expect((await b.water.watchSettings().first)!.goalGlasses, 6);
    // Rien à renvoyer : ce qui vient du serveur n'est pas « à synchroniser ».
    expect(await b.sync.hasUnsyncedData(), isFalse);
  });

  test('une modification locale plus récente n’est pas écrasée', () async {
    final id = await a.addParacetamol();
    await a.admin.claimFor(user);
    await a.sync.sync(user);
    await b.sync.sync(user);

    // B renomme (pas encore envoyé), puis A renomme plus tôt et envoie.
    final medB = (await b.meds.getMedication(id))!;
    await Future<void>.delayed(const Duration(seconds: 1));
    await b.meds.saveMedication(medB.copyWith(name: 'Doliprane'));
    await b.sync.sync(user);

    expect(remote.rows('medications').single['name'], 'Doliprane');
    await a.sync.sync(user);
    expect((await a.meds.getMedication(id))!.name, 'Doliprane');
  });

  test(
    'une même prise confirmée sur deux téléphones : une seule réponse',
    () async {
      final id = await a.addParacetamol();
      await a.admin.claimFor(user);
      await a.sync.sync(user);
      await b.sync.sync(user);
      final at = DateTime(2026, 11, 8, 8);

      await a.meds.saveIntakeLog(
        IntakeLog(
          medicationId: id,
          scheduledAt: at,
          status: IntakeStatus.taken,
        ),
      );
      await a.sync.sync(user);
      await Future<void>.delayed(const Duration(seconds: 1));
      await b.meds.saveIntakeLog(
        IntakeLog(
          medicationId: id,
          scheduledAt: at,
          status: IntakeStatus.missed,
        ),
      );
      await b.sync.sync(user);
      await a.sync.sync(user);

      expect(remote.rows('intake_logs'), hasLength(1));
      expect(remote.rows('intake_logs').single['status'], 'missed');
      final onA = await a.meds
          .watchIntakeLogs(DateTime(2026, 11, 8), DateTime(2026, 11, 9))
          .first;
      expect(onA.single.status, IntakeStatus.missed);
    },
  );

  test('un seul objectif d’eau actif : le plus récent gagne', () async {
    await a.water.saveSettings(const WaterSettings(goalGlasses: 5));
    await a.admin.claimFor(user);
    await a.sync.sync(user);
    await Future<void>.delayed(const Duration(seconds: 1));
    await b.water.saveSettings(const WaterSettings(goalGlasses: 8));
    await b.admin.claimFor(user);

    await b.sync.sync(user);

    final active = remote
        .rows('water_settings')
        .where((r) => r['deleted'] == false);
    expect(active.single['goal_glasses'], 8);
    await a.sync.sync(user);
    expect((await a.water.watchSettings().first)!.goalGlasses, 8);
  });

  test('hors connexion : rien n’est perdu, envoyé plus tard', () async {
    await a.addParacetamol();
    await a.admin.claimFor(user);
    remote.online = false;

    expect(() => a.sync.sync(user), throwsA(anything));
    expect(await a.sync.hasUnsyncedData(), isTrue);

    remote.online = true;
    await a.sync.sync(user);
    expect(await a.sync.hasUnsyncedData(), isFalse);
  });

  group('reconnexion sur le même téléphone', () {
    SessionDataImpl sessionOf(Phone phone, String Function() currentUser) =>
        SessionDataImpl(
          admin: phone.admin,
          sync: SyncCoordinator(
            db: phone.db,
            service: phone.sync,
            currentUserId: currentUser,
            onRemoteChanges: () async {},
          ),
          rescheduleReminders: () async {},
        );

    test('après une déconnexion, on retrouve ses données', () async {
      final session = sessionOf(a, () => user);
      await a.addParacetamol();
      await session.attachTo(user);
      expect(remote.rows('medications'), hasLength(1));
      // La synchro suivante reçoit ses propres lignes : le curseur avance.
      await session.syncNow();

      await session.clear();
      expect(await a.meds.watchMedications().first, isEmpty);

      await session.attachTo(user);
      expect(await a.meds.watchMedications().first, hasLength(1));
    });

    test('après l’effacement des données d’un autre compte, on retrouve les '
        'siennes', () async {
      var current = user;
      final session = sessionOf(a, () => current);
      await a.addParacetamol();
      await session.attachTo(user);
      await session.syncNow();

      // Session fermée par le serveur, sans effacement : l'autre compte
      // qui se connecte provoque l'effacement à ce moment-là.
      current = 'user-autre';
      await session.attachTo(current);
      expect(await a.meds.watchMedications().first, isEmpty);

      current = user;
      await session.attachTo(user);
      expect(await a.meds.watchMedications().first, hasLength(1));
    });
  });

  test(
    'déconnexion : les données de santé sont effacées du téléphone',
    () async {
      await a.addParacetamol();
      await a.water.addLog(
        WaterLog(drankAt: DateTime(2026, 11, 8, 9), ml: 250),
      );

      await a.admin.wipeHealthData();

      expect(
        await a.meds.watchMedications(includeDeleted: true).first,
        isEmpty,
      );
      expect(await a.db.select(a.db.waterLogs).get(), isEmpty);
    },
  );
}
