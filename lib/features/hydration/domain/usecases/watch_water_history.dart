import '../entities/water_log.dart';
import '../entities/water_settings.dart';
import '../repositories/water_repository.dart';

/// Objectif et verres bus sur une période (pour l'historique).
class WatchWaterSettings {
  const WatchWaterSettings(this._repository);

  final WaterRepository _repository;

  Stream<WaterSettings?> call() => _repository.watchSettings();
}

class WatchWaterLogs {
  const WatchWaterLogs(this._repository);

  final WaterRepository _repository;

  Stream<List<WaterLog>> call(DateTime from, DateTime to) =>
      _repository.watchLogs(from, to);
}
