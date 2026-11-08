import '../entities/medication.dart';
import '../repositories/medication_repository.dart';
import '../services/medication_rules.dart';

/// Ajoute ou modifie un traitement après vérification des règles de saisie.
/// (Étape 3 : replanifiera aussi les rappels.)
class SaveMedication {
  const SaveMedication(this._repository);

  final MedicationRepository _repository;

  /// Lève [InvalidMedicationException] si la saisie est incomplète.
  Future<String> call(Medication medication) {
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
    return _repository.saveMedication(cleaned);
  }
}
