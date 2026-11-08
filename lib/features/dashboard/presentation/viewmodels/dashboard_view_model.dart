import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../../auth/di/auth_providers.dart';
import '../../../hydration/di/hydration_providers.dart';
import '../../../medications/di/medications_providers.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/domain/entities/scheduled_intake.dart';
import '../../../medications/domain/services/intake_planner.dart';
import '../../domain/entities/daily_summary.dart';
import '../../domain/services/daily_summary_calculator.dart';

/// Ce qu'affiche l'Accueil.
class DashboardUiState {
  const DashboardUiState({
    required this.now,
    required this.summary,
    this.displayName,
  });

  final DateTime now;

  /// Prénom du compte (« Bonjour, Hery »).
  final String? displayName;
  final AsyncValue<DailySummary> summary;

  bool canConfirm(ScheduledIntake intake) =>
      IntakePlanner.canConfirm(intake, now);
}

final dashboardViewModelProvider =
    NotifierProvider<DashboardViewModel, DashboardUiState>(
      DashboardViewModel.new,
    );

/// ViewModel de l'Accueil : agrège médicaments et eau du jour.
class DashboardViewModel extends Notifier<DashboardUiState> {
  @override
  DashboardUiState build() {
    final now = ref.watch(clockProvider);
    final today = dateOnly(now);
    final plan = ref.watch(dayPlanProvider(today));
    final water = ref.watch(waterDayProvider(today));

    final AsyncValue<DailySummary> summary;
    if (plan.hasValue && water.hasValue) {
      summary = AsyncData(
        DailySummaryCalculator.summarize(plan.requireValue, water.value),
      );
    } else if (plan.hasError || water.hasError) {
      summary = AsyncError(
        plan.error ?? water.error!,
        plan.stackTrace ?? water.stackTrace ?? StackTrace.current,
      );
    } else {
      summary = const AsyncLoading();
    }
    return DashboardUiState(
      now: now,
      summary: summary,
      displayName: ref.watch(currentUserProvider).value?.displayName,
    );
  }

  /// « Confirmer la prise ». Renvoie un message d'erreur, ou null.
  Future<String?> confirm(ScheduledIntake intake) async {
    try {
      await ref.read(confirmIntakeProvider)(intake, ref.read(clockProvider));
      return null;
    } catch (_) {
      return "La prise n'a pas pu être enregistrée. Réessayez.";
    }
  }
}
