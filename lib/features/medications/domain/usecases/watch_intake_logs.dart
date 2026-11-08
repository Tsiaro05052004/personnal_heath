import '../entities/intake_log.dart';
import '../repositories/medication_repository.dart';

/// Prises enregistrées dont l'heure prévue est dans [from, to[.
class WatchIntakeLogs {
  const WatchIntakeLogs(this._repository);

  final MedicationRepository _repository;

  Stream<List<IntakeLog>> call(DateTime from, DateTime to) =>
      _repository.watchIntakeLogs(from, to);
}
