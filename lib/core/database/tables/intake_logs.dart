import 'package:drift/drift.dart';

import '../../../features/medications/domain/entities/intake_status.dart';
import 'medications.dart';
import 'sync_columns.dart';

/// Une prise sur laquelle l'utilisateur a agi (confirmée ou déclarée oubliée).
@DataClassName('IntakeLogRow')
class IntakeLogs extends Table with SyncColumns {
  TextColumn get medicationId => text().references(Medications, #id)();

  /// Date et heure prévues de la prise.
  DateTimeColumn get scheduledAt => dateTime()();

  TextColumn get status => textEnum<IntakeStatus>()();

  /// Heure RÉELLE de confirmation (peut être en retard sur scheduledAt).
  DateTimeColumn get takenAt => dateTime().nullable()();

  /// Unités réellement prises (pour le compteur de comprimés).
  RealColumn get quantityTaken => real().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {medicationId, scheduledAt},
  ];
}
