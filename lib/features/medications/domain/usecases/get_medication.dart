import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class GetMedication {
  const GetMedication(this._repository);

  final MedicationRepository _repository;

  Future<Medication?> call(String id) => _repository.getMedication(id);
}
