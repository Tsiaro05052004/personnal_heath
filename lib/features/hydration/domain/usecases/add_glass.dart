import '../entities/water_log.dart';
import '../repositories/water_repository.dart';
import 'reschedule_water_reminders.dart';

/// « J'ai bu un verre » : un verre de la taille choisie dans l'objectif.
class AddGlass {
  const AddGlass(this._repository, this._reschedule);

  final WaterRepository _repository;
  final RescheduleWaterReminders _reschedule;

  Future<void> call(DateTime now) async {
    final settings = await _repository.watchSettings().first;
    if (settings == null) {
      throw StateError("L'objectif d'eau n'est pas encore défini.");
    }
    await _repository.addLog(WaterLog(drankAt: now, ml: settings.mlPerGlass));
    // Les rappels dont l'objectif intermédiaire est atteint disparaissent.
    await _reschedule();
  }
}
