import '../entities/water_settings.dart';
import '../repositories/water_repository.dart';

/// Objectif enregistré, ou null s'il n'est pas encore défini.
class GetWaterSettings {
  const GetWaterSettings(this._repository);

  final WaterRepository _repository;

  Future<WaterSettings?> call() => _repository.watchSettings().first;
}
