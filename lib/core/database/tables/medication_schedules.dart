import 'package:drift/drift.dart';

import 'medications.dart';
import 'sync_columns.dart';

/// Une heure de prise quotidienne d'un médicament (ex. 08:00).
@DataClassName('MedicationScheduleRow')
class MedicationSchedules extends Table with SyncColumns {
  TextColumn get medicationId => text().references(Medications, #id)();

  /// Minutes depuis minuit en heure locale (08:00 → 480).
  IntColumn get minuteOfDay => integer().customConstraint(
    'NOT NULL CHECK (minute_of_day BETWEEN 0 AND 1439)',
  )();
}
