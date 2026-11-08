import '../entities/water_day.dart';
import '../repositories/water_repository.dart';
import 'reschedule_water_reminders.dart';

/// « Annuler le dernier verre » (appui par erreur).
class UndoLastGlass {
  const UndoLastGlass(this._repository, this._reschedule);

  final WaterRepository _repository;
  final RescheduleWaterReminders _reschedule;

  /// Renvoie false s'il n'y avait aucun verre à annuler.
  Future<bool> call(WaterDay day) async {
    final last = day.lastLog;
    if (last == null) return false;
    await _repository.deleteLog(last.id);
    await _reschedule();
    return true;
  }
}
