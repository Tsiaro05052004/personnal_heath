import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class WatchMedications {
  const WatchMedications(this._repository);

  final MedicationRepository _repository;

  /// [includeDeleted] : aussi les médicaments supprimés (historique).
  Stream<List<Medication>> call({bool includeDeleted = false}) =>
      _repository.watchMedications(includeDeleted: includeDeleted);
}
