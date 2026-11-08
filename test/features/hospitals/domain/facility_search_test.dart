import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/features/hospitals/domain/entities/geo_point.dart';
import 'package:personnal_heath/features/hospitals/domain/entities/health_facility.dart';
import 'package:personnal_heath/features/hospitals/domain/entities/nearby_search.dart';
import 'package:personnal_heath/features/hospitals/domain/repositories/facility_repository.dart';
import 'package:personnal_heath/features/hospitals/domain/services/facility_search.dart';
import 'package:personnal_heath/features/hospitals/domain/services/geo.dart';
import 'package:personnal_heath/features/hospitals/domain/usecases/find_nearby_facilities.dart';

void main() {
  const me = GeoPoint(-18.91, 47.525);
  HealthFacility f(String name, FacilityType type, double dLat, {String? a}) =>
      HealthFacility(
        osmId: name,
        name: name,
        type: type,
        location: GeoPoint(me.latitude + dLat, me.longitude),
        address: a,
      );
  final facilities = [
    f('Clinique des Sœurs', FacilityType.clinic, 0.018),
    f(
      'CHU Joseph Ravoahangy',
      FacilityType.publicHospital,
      0.0108,
      a: 'Ampefiloha, Antananarivo',
    ),
    f('Centre de santé Isotry', FacilityType.healthCentre, 0.03),
  ];

  test('distance à vol d’oiseau', () {
    // 0,01° de latitude ≈ 1,11 km.
    expect(
      Geo.distanceMeters(me, const GeoPoint(-18.90, 47.525)),
      closeTo(1112, 5),
    );
  });

  test('du plus proche au plus lointain', () {
    final result = FacilitySearch.apply(facilities: facilities, from: me);
    expect(result.map((n) => n.facility.name), [
      'CHU Joseph Ravoahangy',
      'Clinique des Sœurs',
      'Centre de santé Isotry',
    ]);
    expect(result.first.distanceMeters, closeTo(1200, 10));
  });

  test('filtres Hôpitaux / Cliniques', () {
    expect(
      FacilitySearch.apply(
        facilities: facilities,
        from: me,
        filter: FacilityFilter.hospitals,
      ).map((n) => n.facility.name),
      ['CHU Joseph Ravoahangy'],
    );
    expect(
      FacilitySearch.apply(
        facilities: facilities,
        from: me,
        filter: FacilityFilter.clinics,
      ),
      hasLength(2),
    );
  });

  test('recherche par nom ou quartier, sans accents ni majuscules', () {
    List<String> search(String q) => FacilitySearch.apply(
      facilities: facilities,
      from: me,
      query: q,
    ).map((n) => n.facility.name).toList();

    expect(search('soeurs'), ['Clinique des Sœurs']);
    expect(search('SANTE isotry'), ['Centre de santé Isotry']);
    expect(search('ampefiloha'), ['CHU Joseph Ravoahangy']);
    expect(search('inconnu'), isEmpty);
  });

  test('cherche plus loin s’il y a trop peu d’établissements', () async {
    final repo = _FakeRepository({
      5000: [facilities.first],
      20000: facilities,
    });
    final result = await FindNearbyFacilities(repo)(me);
    expect(repo.radii, [5000, 20000]);
    expect(result.facilities, hasLength(3));
  });
}

class _FakeRepository implements FacilityRepository {
  _FakeRepository(this.byRadius);

  final Map<int, List<HealthFacility>> byRadius;
  final radii = <int>[];

  @override
  Future<NearbySearch> nearby(
    GeoPoint center, {
    required int radiusMeters,
  }) async {
    radii.add(radiusMeters);
    return NearbySearch(
      facilities: byRadius[radiusMeters]!,
      fetchedAt: DateTime(2026, 11, 8),
      fromCache: false,
    );
  }

  @override
  Future<NearbySearch?> cached() async => null;
}
