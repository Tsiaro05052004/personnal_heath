import '../entities/water_log.dart';
import '../entities/water_settings.dart';

/// Contrat d'accès à l'objectif et aux verres (base locale, hors ligne).
abstract interface class WaterRepository {
  /// Objectif enregistré ; null tant que l'utilisateur ne l'a pas défini.
  Stream<WaterSettings?> watchSettings();

  Future<void> saveSettings(WaterSettings settings);

  /// Verres bus dans [from, to[, du plus ancien au plus récent.
  Stream<List<WaterLog>> watchLogs(DateTime from, DateTime to);

  Future<void> addLog(WaterLog log);

  Future<void> deleteLog(String id);
}
