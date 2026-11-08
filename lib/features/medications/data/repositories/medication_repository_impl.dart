import '../../domain/entities/intake_log.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/local/medication_local_data_source.dart';
import '../mappers/medication_mapper.dart';

/// Implémentation hors ligne : la base locale est la source de vérité.
/// (Étape 7 : la synchronisation Supabase s'ajoutera ici.)
class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._local);

  final MedicationLocalDataSource _local;

  @override
  Stream<List<Medication>> watchMedications({bool includeDeleted = false}) =>
      _local
          .watchAll(includeDeleted: includeDeleted)
          .map((rows) => rows.map(MedicationMapper.toEntity).toList());

  @override
  Future<Medication?> getMedication(String id) async {
    final row = await _local.getById(id);
    return row == null ? null : MedicationMapper.toEntity(row);
  }

  @override
  Future<String> saveMedication(Medication medication) => _local.upsert(
    MedicationMapper.toCompanion(medication),
    [for (final t in medication.doseTimes) t.minuteOfDay],
  );

  @override
  Future<void> deleteMedication(String id) => _local.softDelete(id);

  @override
  Stream<List<IntakeLog>> watchIntakeLogs(DateTime from, DateTime to) => _local
      .watchLogs(from, to)
      .map((rows) => rows.map(MedicationMapper.logToEntity).toList());

  @override
  Future<void> saveIntakeLog(IntakeLog log) =>
      _local.upsertLog(MedicationMapper.logToCompanion(log));
}
