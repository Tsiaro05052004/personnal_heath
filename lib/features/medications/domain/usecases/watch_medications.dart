import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class WatchMedications {
  const WatchMedications(this._repository);

  final MedicationRepository _repository;

  Stream<List<Medication>> call() => _repository.watchMedications();
}
