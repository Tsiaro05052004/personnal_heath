import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../di/medications_providers.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/scheduled_intake.dart';
import 'medication_list_ui_state.dart';

/// Jour choisi dans le bandeau (null = aujourd'hui). Séparé du ViewModel,
/// qui est recréé à chaque tic de l'horloge.
final _selectedDayProvider = NotifierProvider<_SelectedDay, DateTime?>(
  _SelectedDay.new,
);

class _SelectedDay extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime day) => state = dateOnly(day);
}

final medicationListViewModelProvider =
    NotifierProvider<MedicationListViewModel, MedicationListUiState>(
      MedicationListViewModel.new,
    );

/// ViewModel de l'écran « Mes médicaments » : jour choisi, prises du jour,
/// confirmation / prise non prise.
class MedicationListViewModel extends Notifier<MedicationListUiState> {
  @override
  MedicationListUiState build() {
    final now = ref.watch(clockProvider);
    final today = dateOnly(now);
    final day = ref.watch(_selectedDayProvider) ?? today;
    return MedicationListUiState(
      now: now,
      today: today,
      selectedDay: day,
      plan: ref.watch(dayPlanProvider(day)),
    );
  }

  void selectDay(DateTime day) =>
      ref.read(_selectedDayProvider.notifier).select(day);

  /// Renvoie un message d'erreur à afficher, ou null si tout va bien.
  Future<String?> confirmIntake(ScheduledIntake intake) => _run(
    () => ref.read(confirmIntakeProvider)(intake, ref.read(clockProvider)),
  );

  Future<String?> markMissed(ScheduledIntake intake) => _run(
    () => ref.read(markIntakeMissedProvider)(intake, ref.read(clockProvider)),
  );

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (_) {
      return "La prise n'a pas pu être enregistrée. Réessayez.";
    }
  }
}
