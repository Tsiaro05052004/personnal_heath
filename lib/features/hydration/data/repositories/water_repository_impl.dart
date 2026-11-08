import '../../domain/entities/water_log.dart';
import '../../domain/entities/water_settings.dart';
import '../../domain/repositories/water_repository.dart';
import '../datasources/local/water_local_data_source.dart';
import '../mappers/water_mapper.dart';

/// Implémentation hors ligne : la base locale est la source de vérité.
class WaterRepositoryImpl implements WaterRepository {
  WaterRepositoryImpl(this._local);

  final WaterLocalDataSource _local;

  @override
  Stream<WaterSettings?> watchSettings() => _local.watchSettings().map(
    (row) => row == null ? null : WaterMapper.settingsToEntity(row),
  );

  @override
  Future<void> saveSettings(WaterSettings settings) =>
      _local.saveSettings(WaterMapper.settingsToCompanion(settings));

  @override
  Stream<List<WaterLog>> watchLogs(DateTime from, DateTime to) => _local
      .watchLogs(from, to)
      .map((rows) => rows.map(WaterMapper.logToEntity).toList());

  @override
  Future<void> addLog(WaterLog log) =>
      _local.addLog(WaterMapper.logToCompanion(log));

  @override
  Future<void> deleteLog(String id) => _local.softDeleteLog(id);
}
