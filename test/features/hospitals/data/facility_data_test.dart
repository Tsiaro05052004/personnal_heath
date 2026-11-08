import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/core/database/app_database.dart';
import 'package:personnal_heath/features/hospitals/data/datasources/local/facility_cache.dart';
import 'package:personnal_heath/features/hospitals/data/mappers/overpass_mapper.dart';
import 'package:personnal_heath/features/hospitals/data/repositories/facility_repository_impl.dart';
import 'package:personnal_heath/features/hospitals/domain/entities/health_facility.dart';

import '../../../helpers/fake_hospitals.dart';

void main() {
  test('lit la réponse Overpass (nœuds, bâtiments, sans nom ignorés)', () {
    final list = OverpassMapper.facilities(overpassSample);
    expect(list.map((f) => f.osmId), ['node/1', 'way/2', 'node/3']);

    final chu = list.first;
    expect(chu.type, FacilityType.publicHospital);
    expect(chu.address, 'Ampefiloha, Antananarivo');
    expect(chu.phone, '+261 20 22 279 79');
    expect(list[1].location.latitude, -18.928);
    expect(list[2].type, FacilityType.healthCentre);
  });

  group('dépôt', () {
    late AppDatabase db;
    late FakeOverpass overpass;
    late FacilityRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      overpass = FakeOverpass();
      repository = FacilityRepositoryImpl(
        overpass.api,
        FacilityCache(db),
        () => DateTime(2026, 11, 8, 14),
      );
    });
    tearDown(() => db.close());

    test('demande les établissements autour de la position', () async {
      final result = await repository.nearby(testPosition, radiusMeters: 5000);
      expect(result.fromCache, isFalse);
      expect(result.facilities, hasLength(3));
      expect(overpass.lastQuery, contains('around:5000,-18.91,47.525'));
      expect(overpass.lastQuery, contains('hospital|clinic'));
    });

    test('hors connexion : la dernière liste enregistrée', () async {
      await repository.nearby(testPosition, radiusMeters: 5000);
      overpass.online = false;

      final result = await repository.nearby(testPosition, radiusMeters: 5000);
      expect(result.fromCache, isTrue);
      expect(result.fetchedAt, DateTime(2026, 11, 8, 14));
      expect(
        result.facilities.map((f) => f.name),
        contains('CHU Joseph Ravoahangy Andrianavalona'),
      );
    });

    test('ni réseau ni liste enregistrée : erreur', () async {
      overpass.online = false;
      expect(
        repository.nearby(testPosition, radiusMeters: 5000),
        throwsA(anything),
      );
    });
  });
}
