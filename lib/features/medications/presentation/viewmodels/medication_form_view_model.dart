import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../di/medications_providers.dart';
import '../../domain/entities/dose_time.dart';
import '../../domain/entities/meal_instruction.dart';
import '../../domain/entities/medication.dart';
import '../../domain/services/medication_rules.dart';
import 'medication_form_ui_state.dart';

/// Formulaire en 3 étapes. Argument : id du médicament à modifier, ou null
/// pour un nouveau.
final medicationFormViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<MedicationFormViewModel, MedicationFormUiState, String?>(
      MedicationFormViewModel.new,
    );

class MedicationFormViewModel extends AsyncNotifier<MedicationFormUiState> {
  MedicationFormViewModel(this.medicationId);

  final String? medicationId;

  /// Bornes de la quantité par prise (pas de 0,5 pour les demi-comprimés).
  static const minQuantity = MedicationRules.quantityStep;
  static const maxQuantity = 20.0;

  @override
  Future<MedicationFormUiState> build() async {
    // ref.read (et non watch) : le formulaire ne doit pas se réinitialiser
    // quand l'horloge avance.
    final id = medicationId;
    if (id != null) {
      final medication = await ref.read(getMedicationProvider)(id);
      if (medication == null) throw StateError('Médicament introuvable');
      return MedicationFormUiState.fromMedication(medication);
    }
    return MedicationFormUiState(
      times: MedicationRules.defaultTimes(1),
      startDate: dateOnly(ref.read(clockProvider)),
    );
  }

  MedicationFormUiState get _form => state.requireValue;

  void _update(MedicationFormUiState Function(MedicationFormUiState) change) {
    if (!state.hasValue) return;
    state = AsyncData(change(_form));
  }

  void setName(String v) => _update((s) => s.copyWith(name: v));
  void setDosage(String v) => _update((s) => s.copyWith(dosage: v));
  void setUnit(String v) => _update((s) => s.copyWith(unit: v));
  void setNotes(String v) => _update((s) => s.copyWith(notes: v));
  void setMealInstruction(MealInstruction v) =>
      _update((s) => s.copyWith(mealInstruction: v));

  /// Change le nombre de prises par jour : horaires proposés par défaut,
  /// que l'utilisateur ajuste ensuite d'après son ordonnance.
  void setFrequency(int frequency) => _update(
    (s) => s.frequency == frequency
        ? s
        : s.copyWith(
            times: MedicationRules.defaultTimes(frequency),
            errors: const {},
          ),
  );

  void setTime(int index, DoseTime time) => _update(
    (s) => s.copyWith(times: [...s.times]..[index] = time, errors: const {}),
  );

  void incrementQuantity() => _update(
    (s) => s.copyWith(
      quantity: (s.quantity + MedicationRules.quantityStep).clamp(
        minQuantity,
        maxQuantity,
      ),
    ),
  );

  void decrementQuantity() => _update(
    (s) => s.copyWith(
      quantity: (s.quantity - MedicationRules.quantityStep).clamp(
        minQuantity,
        maxQuantity,
      ),
    ),
  );

  void setStartDate(DateTime date) =>
      _update((s) => s.copyWith(startDate: dateOnly(date), errors: const {}));

  void setEndDate(DateTime? date) => _update(
    (s) => s.copyWith(
      endDate: () => date == null ? null : dateOnly(date),
      errors: const {},
    ),
  );

  void goToStep(FormStep step) =>
      _update((s) => s.copyWith(step: step, errors: const {}));

  /// Étape précédente. Renvoie false sur la première étape (l'écran se
  /// ferme alors).
  bool back() {
    final s = _form;
    if (s.step.index == 0) return false;
    goToStep(FormStep.values[s.step.index - 1]);
    return true;
  }

  /// « Continuer » / « Enregistrer ». Renvoie true quand le médicament est
  /// enregistré (l'écran se ferme alors).
  Future<bool> next() async {
    final s = _form;
    final errors = s.errorsFor(s.step);
    if (errors.isNotEmpty) {
      _update((s) => s.copyWith(errors: errors));
      return false;
    }
    if (!s.isLastStep) {
      goToStep(FormStep.values[s.step.index + 1]);
      return false;
    }
    _update((s) => s.copyWith(saving: true));
    try {
      await ref.read(saveMedicationProvider)(s.toMedication());
      return true;
    } on InvalidMedicationException catch (e) {
      // Ne devrait pas arriver (chaque étape est vérifiée) : on revient à
      // la première étape en erreur.
      final step = FormStep.values.firstWhere(
        (st) => st.errors.intersection(e.errors).isNotEmpty,
        orElse: () => s.step,
      );
      _update((s) => s.copyWith(step: step, errors: e.errors, saving: false));
      return false;
    }
  }

  Future<void> delete() async {
    final id = medicationId;
    if (id != null) await ref.read(deleteMedicationProvider)(id);
  }
}
