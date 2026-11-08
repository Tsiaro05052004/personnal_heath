import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/health_facility.dart';

abstract final class FacilityCacheMapper {
  static HealthFacility toEntity(HospitalRow row) => HealthFacility(
    osmId: row.osmId,
    name: row.name,
    type: FacilityType.values.asNameMap()[row.type] ?? FacilityType.clinic,
    location: GeoPoint(row.latitude, row.longitude),
    address: row.address,
    phone: row.phone,
  );

  static HospitalsCacheCompanion toRow(HealthFacility f, DateTime fetchedAt) =>
      HospitalsCacheCompanion.insert(
        osmId: f.osmId,
        name: f.name,
        type: f.type.name,
        address: Value(f.address),
        latitude: f.location.latitude,
        longitude: f.location.longitude,
        phone: Value(f.phone),
        fetchedAt: fetchedAt,
      );
}
