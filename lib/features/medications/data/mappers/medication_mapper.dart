import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/dose_time.dart';
import '../../domain/entities/intake_log.dart';
import '../../domain/entities/medication.dart';
import '../datasources/local/medication_local_data_source.dart';

/// Conversions lignes Drift ↔ entités du domaine. Les classes Drift ne
/// sortent jamais de data/.
abstract final class MedicationMapper {
  static Medication toEntity(MedicationWithSchedules row) {
    final m = row.medication;
    return Medication(
      id: m.id,
      name: m.name,
      dosage: m.dosage,
      quantityPerIntake: m.quantityPerIntake,
      unit: m.unit,
      mealInstruction: m.mealInstruction,
      notes: m.notes,
      startDate: m.startDate,
      endDate: m.endDate,
      doseTimes: [
        for (final s in row.schedules) DoseTime.fromMinuteOfDay(s.minuteOfDay),
      ],
    );
  }

  static MedicationsCompanion toCompanion(Medication m) => MedicationsCompanion(
    id: m.isNew ? const Value.absent() : Value(m.id),
    name: Value(m.name),
    dosage: Value(m.dosage),
    quantityPerIntake: Value(m.quantityPerIntake),
    unit: Value(m.unit),
    mealInstruction: Value(m.mealInstruction),
    notes: Value(m.notes),
    startDate: Value(m.startDate),
    endDate: Value(m.endDate),
    active: const Value(true),
  );

  static IntakeLog logToEntity(IntakeLogRow row) => IntakeLog(
    id: row.id,
    medicationId: row.medicationId,
    scheduledAt: row.scheduledAt,
    status: row.status,
    takenAt: row.takenAt,
    quantityTaken: row.quantityTaken,
  );

  static IntakeLogsCompanion logToCompanion(IntakeLog log) =>
      IntakeLogsCompanion(
        id: log.id.isEmpty ? const Value.absent() : Value(log.id),
        medicationId: Value(log.medicationId),
        scheduledAt: Value(log.scheduledAt),
        status: Value(log.status),
        takenAt: Value(log.takenAt),
        quantityTaken: Value(log.quantityTaken),
      );
}
