import '../../domain/entities/dose_time.dart';
import '../../domain/entities/meal_instruction.dart';
import '../../domain/entities/medication.dart';
import '../../domain/services/medication_rules.dart';

/// Les 3 étapes du formulaire.
enum FormStep {
  medication('Médicament', {MedicationError.emptyName}),
  schedule('Horaires', {
    MedicationError.noDoseTime,
    MedicationError.duplicateDoseTime,
    MedicationError.invalidQuantity,
  }),
  duration('Durée et consignes', {MedicationError.endBeforeStart});

  const FormStep(this.title, this.errors);

  final String title;

  /// Erreurs vérifiées avant de quitter cette étape.
  final Set<MedicationError> errors;
}

/// État du formulaire « Nouveau médicament » / « Modifier ».
class MedicationFormUiState {
  const MedicationFormUiState({
    this.id = '',
    this.step = FormStep.medication,
    this.name = '',
    this.dosage = '',
    this.unit = 'comprimé',
    required this.times,
    this.quantity = 1,
    this.mealInstruction = MealInstruction.none,
    required this.startDate,
    this.endDate,
    this.notes = '',
    this.errors = const {},
    this.saving = false,
  });

  factory MedicationFormUiState.fromMedication(Medication m) =>
      MedicationFormUiState(
        id: m.id,
        name: m.name,
        dosage: m.dosage,
        unit: m.unit,
        times: m.doseTimes,
        quantity: m.quantityPerIntake,
        mealInstruction: m.mealInstruction,
        startDate: m.startDate,
        endDate: m.endDate,
        notes: m.notes ?? '',
      );

  final String id;
  final FormStep step;
  final String name;
  final String dosage;
  final String unit;
  final List<DoseTime> times;
  final double quantity;
  final MealInstruction mealInstruction;
  final DateTime startDate;
  final DateTime? endDate;
  final String notes;

  /// Erreurs de l'étape affichée (après un appui sur « Continuer »).
  final Set<MedicationError> errors;
  final bool saving;

  bool get isEdit => id.isNotEmpty;
  int get frequency => times.length;
  bool get isLastStep => step == FormStep.values.last;

  /// « Étape 2 sur 3 · Horaires »
  String get stepLabel =>
      'Étape ${step.index + 1} sur ${FormStep.values.length} · ${step.title}';

  Medication toMedication() => Medication(
    id: id,
    name: name,
    dosage: dosage,
    quantityPerIntake: quantity,
    unit: unit,
    mealInstruction: mealInstruction,
    notes: notes,
    startDate: startDate,
    endDate: endDate,
    doseTimes: times,
  );

  /// Erreurs de l'étape [s] pour la saisie actuelle.
  Set<MedicationError> errorsFor(FormStep s) {
    return MedicationRules.validate(toMedication()).intersection(s.errors);
  }

  MedicationFormUiState copyWith({
    FormStep? step,
    String? name,
    String? dosage,
    String? unit,
    List<DoseTime>? times,
    double? quantity,
    MealInstruction? mealInstruction,
    DateTime? startDate,
    DateTime? Function()? endDate,
    String? notes,
    Set<MedicationError>? errors,
    bool? saving,
  }) => MedicationFormUiState(
    id: id,
    step: step ?? this.step,
    name: name ?? this.name,
    dosage: dosage ?? this.dosage,
    unit: unit ?? this.unit,
    times: times ?? this.times,
    quantity: quantity ?? this.quantity,
    mealInstruction: mealInstruction ?? this.mealInstruction,
    startDate: startDate ?? this.startDate,
    endDate: endDate != null ? endDate() : this.endDate,
    notes: notes ?? this.notes,
    errors: errors ?? this.errors,
    saving: saving ?? this.saving,
  );
}
