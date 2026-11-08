import '../entities/dose_time.dart';
import '../entities/medication.dart';

/// Raisons pour lesquelles un médicament ne peut pas être enregistré.
/// Les messages sont rédigés par la présentation.
enum MedicationError {
  emptyName,
  noDoseTime,
  duplicateDoseTime,
  invalidQuantity,
  endBeforeStart,
}

/// Erreur levée par les use cases quand un médicament est invalide.
class InvalidMedicationException implements Exception {
  const InvalidMedicationException(this.errors);

  final Set<MedicationError> errors;

  @override
  String toString() => 'InvalidMedicationException($errors)';
}

/// Règles de saisie d'un traitement. L'application recopie l'ordonnance :
/// elle ne propose ni ne modifie jamais de dose.
abstract final class MedicationRules {
  static const maxFrequency = 4;
  static const quantityStep = 0.5;

  static Set<MedicationError> validate(Medication medication) => {
    if (medication.name.trim().isEmpty) MedicationError.emptyName,
    if (medication.doseTimes.isEmpty) MedicationError.noDoseTime,
    if (medication.doseTimes.toSet().length != medication.doseTimes.length)
      MedicationError.duplicateDoseTime,
    if (medication.quantityPerIntake <= 0) MedicationError.invalidQuantity,
    if (medication.endDate?.isBefore(medication.startDate) ?? false)
      MedicationError.endBeforeStart,
  };

  /// Horaires proposés par défaut selon le nombre de prises par jour.
  /// L'utilisateur les ajuste ensuite pour suivre son ordonnance.
  static List<DoseTime> defaultTimes(int frequency) => switch (frequency) {
    1 => const [DoseTime(8, 0)],
    2 => const [DoseTime(8, 0), DoseTime(20, 0)],
    3 => const [DoseTime(8, 0), DoseTime(14, 0), DoseTime(20, 0)],
    _ => const [
      DoseTime(8, 0),
      DoseTime(12, 0),
      DoseTime(16, 0),
      DoseTime(20, 0),
    ],
  };
}
