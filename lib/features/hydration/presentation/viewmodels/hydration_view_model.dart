import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../di/hydration_providers.dart';
import '../../domain/entities/water_day.dart';
import '../../domain/services/water_reminder_planner.dart';

/// Ce qu'affiche l'écran « Mon eau du jour ».
class HydrationUiState {
  const HydrationUiState({required this.day, required this.now});

  /// null dans AsyncData = objectif pas encore défini.
  final AsyncValue<WaterDay?> day;
  final DateTime now;

  /// Prochain rappel d'aujourd'hui, s'il y en a un.
  DateTime? get nextReminder {
    final d = day.value;
    if (d == null) return null;
    return WaterReminderPlanner.nextNudge(
      settings: d.settings,
      glassesToday: d.glasses,
      now: now,
    );
  }
}

/// Résultat de « J'ai bu un verre », pour le message affiché.
enum GlassResult { added, goalReached, failed }

final hydrationViewModelProvider =
    NotifierProvider<HydrationViewModel, HydrationUiState>(
      HydrationViewModel.new,
    );

class HydrationViewModel extends Notifier<HydrationUiState> {
  @override
  HydrationUiState build() {
    final now = ref.watch(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    return HydrationUiState(day: ref.watch(waterDayProvider(today)), now: now);
  }

  Future<GlassResult> addGlass() async {
    final before = state.day.value;
    try {
      await ref.read(addGlassProvider)(ref.read(clockProvider));
    } catch (_) {
      return GlassResult.failed;
    }
    // L'objectif vient d'être atteint avec CE verre : on félicite.
    if (before != null && before.glasses + 1 == before.goal) {
      return GlassResult.goalReached;
    }
    return GlassResult.added;
  }

  /// Renvoie false s'il n'y avait rien à annuler ou en cas d'erreur.
  Future<bool> undoLastGlass() async {
    final day = state.day.value;
    if (day == null) return false;
    try {
      return await ref.read(undoLastGlassProvider)(day);
    } catch (_) {
      return false;
    }
  }
}
