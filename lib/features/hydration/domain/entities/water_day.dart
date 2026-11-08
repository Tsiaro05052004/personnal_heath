import 'dart:math' as math;

import 'water_log.dart';
import 'water_settings.dart';

/// L'eau d'une journée : objectif et verres bus.
class WaterDay {
  const WaterDay({
    required this.day,
    required this.settings,
    required this.logs,
  });

  /// Minuit du jour concerné.
  final DateTime day;
  final WaterSettings settings;

  /// Verres bus ce jour-là, du plus ancien au plus récent.
  final List<WaterLog> logs;

  int get glasses => logs.length;
  int get goal => settings.goalGlasses;
  int get mlDrunk => logs.fold(0, (sum, log) => sum + log.ml);
  int get mlGoal => settings.goalMl;
  bool get goalReached => glasses >= goal;
  int get remaining => math.max(0, goal - glasses);

  /// Progression entre 0 et 1 (plafonnée : boire plus n'est pas un but).
  double get progress => goal == 0 ? 1 : math.min(1, glasses / goal);

  WaterLog? get lastLog => logs.isEmpty ? null : logs.last;
}
