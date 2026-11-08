import '../entities/medication.dart';
import '../repositories/medication_repository.dart';
import '../services/medication_rules.dart';
import 'reschedule_reminders.dart';

/// Ajoute ou modifie un traitement après vérification des règles de saisie,
/// puis replanifie les rappels (modifier un traitement = nouveaux rappels).
class SaveMedication {
  const SaveMedication(this._repository, this._reschedule);

  final MedicationRepository _repository;
  final RescheduleReminders _reschedule;

  /// Lève [InvalidMedicationException] si la saisie est incomplète.
  Future<String> call(Medication medication) async {
    final cleaned = medication.copyWith(
      name: medication.name.trim(),
      dosage: medication.dosage.trim(),
      notes: () {
        final notes = medication.notes?.trim();
        return notes == null || notes.isEmpty ? null : notes;
      },
    );
    final errors = MedicationRules.validate(cleaned);
    if (errors.isNotEmpty) throw InvalidMedicationException(errors);
    final id = await _repository.saveMedication(cleaned);
    await _reschedule();
    return id;
  }
}
