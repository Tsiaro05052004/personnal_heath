import '../repositories/medication_repository.dart';
import 'reschedule_reminders.dart';

/// Supprime un traitement et arrête ses rappels.
class DeleteMedication {
  const DeleteMedication(this._repository, this._reschedule);

  final MedicationRepository _repository;
  final RescheduleReminders _reschedule;

  Future<void> call(String id) async {
    await _repository.deleteMedication(id);
    await _reschedule();
  }
}
