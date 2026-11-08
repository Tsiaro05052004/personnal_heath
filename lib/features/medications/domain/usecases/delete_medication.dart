import '../repositories/medication_repository.dart';

/// Supprime un traitement. (Étape 3 : annulera aussi ses rappels.)
class DeleteMedication {
  const DeleteMedication(this._repository);

  final MedicationRepository _repository;

  Future<void> call(String id) => _repository.deleteMedication(id);
}
