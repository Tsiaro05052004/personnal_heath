import 'dart:async';

import '../entities/day_plan.dart';
import '../entities/intake_log.dart';
import '../entities/medication.dart';
import '../repositories/medication_repository.dart';
import '../services/intake_planner.dart';

/// Les prises d'une journée, recalculées à chaque modification des
/// médicaments ou des prises enregistrées.
class WatchDayPlan {
  const WatchDayPlan(this._repository);

  final MedicationRepository _repository;

  /// [now] est fourni par l'appelant (horloge) pour calculer les états.
  Stream<DayPlan> call(DateTime day, DateTime now) {
    final from = dateOnly(day);
    final to = DateTime(from.year, from.month, from.day + 1);

    late StreamController<DayPlan> controller;
    StreamSubscription<List<Medication>>? medsSub;
    StreamSubscription<List<IntakeLog>>? logsSub;
    List<Medication>? medications;
    List<IntakeLog>? logs;

    void emit() {
      if (medications == null || logs == null) return;
      controller.add(
        IntakePlanner.planDay(
          medications: medications!,
          logs: logs!,
          day: from,
          now: now,
        ),
      );
    }

    controller = StreamController<DayPlan>(
      onListen: () {
        medsSub = _repository.watchMedications().listen((value) {
          medications = value;
          emit();
        }, onError: controller.addError);
        logsSub = _repository.watchIntakeLogs(from, to).listen((value) {
          logs = value;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await medsSub?.cancel();
        await logsSub?.cancel();
      },
    );
    return controller.stream;
  }
}
