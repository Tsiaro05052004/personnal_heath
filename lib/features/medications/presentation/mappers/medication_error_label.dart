import '../../domain/services/medication_rules.dart';

extension MedicationErrorLabel on MedicationError {
  String get label => switch (this) {
    MedicationError.emptyName => 'Écrivez le nom du médicament.',
    MedicationError.noDoseTime => 'Choisissez au moins une heure de prise.',
    MedicationError.duplicateDoseTime =>
      'Deux prises ont la même heure : changez-en une.',
    MedicationError.invalidQuantity => 'La quantité doit être positive.',
    MedicationError.endBeforeStart =>
      'La date de fin doit être après la date de début.',
  };
}
