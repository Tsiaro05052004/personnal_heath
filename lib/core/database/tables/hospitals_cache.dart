import 'package:drift/drift.dart';

/// Derniers établissements de santé récupérés d'OpenStreetMap, pour que la
/// carte reste utilisable hors ligne. Local uniquement (pas synchronisé).
@DataClassName('HospitalRow')
class HospitalsCache extends Table {
  /// Identifiant OSM, ex. « node/123456 ».
  TextColumn get osmId => text()();
  TextColumn get name => text()();

  /// hospital, clinic, doctors, health_centre…
  TextColumn get type => text()();
  TextColumn get address => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {osmId};
}
