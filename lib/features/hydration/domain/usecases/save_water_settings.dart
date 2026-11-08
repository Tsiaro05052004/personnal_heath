import '../entities/water_settings.dart';
import '../repositories/water_repository.dart';
import '../services/water_rules.dart';
import 'reschedule_water_reminders.dart';

/// Enregistre l'objectif d'eau puis replanifie les rappels.
class SaveWaterSettings {
  const SaveWaterSettings(this._repository, this._reschedule);

  final WaterRepository _repository;
  final RescheduleWaterReminders _reschedule;

  /// Lève [InvalidWaterSettingsException] si la saisie est incohérente.
  Future<void> call(WaterSettings settings) async {
    final errors = WaterRules.validate(settings);
    if (errors.isNotEmpty) throw InvalidWaterSettingsException(errors);
    await _repository.saveSettings(settings);
    await _reschedule();
  }
}
