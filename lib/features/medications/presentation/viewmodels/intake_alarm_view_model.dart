import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../di/medications_providers.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/scheduled_intake.dart';
import '../../domain/services/intake_planner.dart';
import '../mappers/dose_labels.dart';

/// Prise concernée par l'alarme.
typedef IntakeRef = ({String medicationId, DateTime scheduledAt});

/// Ce qu'affiche l'écran d'alarme.
class IntakeAlarmUiState {
  const IntakeAlarmUiState({required this.intake, required this.now});

  /// Null si la prise n'existe plus (médicament supprimé ou modifié).
  final ScheduledIntake? intake;
  final DateTime now;

  bool get canConfirm =>
      intake != null && IntakePlanner.canConfirm(intake!, now);

  bool get canMarkMissed =>
      intake != null && IntakePlanner.canMarkMissed(intake!, now);

  /// « Plus tard » tant que la prise n'est pas confirmée.
  bool get canSnooze => intake != null && intake!.state != IntakeState.taken;
}

final intakeAlarmViewModelProvider = NotifierProvider.autoDispose
    .family<IntakeAlarmViewModel, AsyncValue<IntakeAlarmUiState>, IntakeRef>(
      IntakeAlarmViewModel.new,
    );

/// ViewModel de l'écran d'alarme : « J'ai pris », « Plus tard »,
/// « Je ne l'ai pas pris ».
class IntakeAlarmViewModel extends Notifier<AsyncValue<IntakeAlarmUiState>> {
  IntakeAlarmViewModel(this.target);

  final IntakeRef target;

  @override
  AsyncValue<IntakeAlarmUiState> build() {
    final now = ref.watch(clockProvider);
    final plan = ref.watch(dayPlanProvider(dateOnly(target.scheduledAt)));
    return plan.whenData(
      (p) => IntakeAlarmUiState(
        now: now,
        intake: p.intakes
            .where(
              (i) =>
                  i.medication.id == target.medicationId &&
                  i.scheduledAt == target.scheduledAt,
            )
            .firstOrNull,
      ),
    );
  }

  ScheduledIntake? get _intake => state.value?.intake;

  /// Arrête la sonnerie des rappels affichés de cette prise (l'utilisateur
  /// quitte l'écran d'alarme sans répondre).
  Future<void> silence() async {
    final intake = _intake;
    if (intake == null) return;
    try {
      await ref.read(silenceReminderProvider)(intake);
    } catch (_) {
      // Sans gravité : la sonnerie s'arrête seule au bout de 5 min.
    }
  }

  /// Chaque action renvoie le message à afficher.
  Future<String> confirm() => _run(() async {
    await ref.read(confirmIntakeProvider)(_intake!, ref.read(clockProvider));
    return 'Prise de ${_intake!.medication.name} confirmée.';
  });

  Future<String> snooze() => _run(() async {
    final at = await ref.read(snoozeReminderProvider)(
      _intake!,
      ref.read(clockProvider),
    );
    return 'Je vous le rappelle à ${DoseLabels.hour(at)}.';
  });

  Future<String> markMissed() => _run(() async {
    await ref.read(markIntakeMissedProvider)(_intake!, ref.read(clockProvider));
    return 'Prise notée comme non prise.';
  });

  Future<String> _run(Future<String> Function() action) async {
    if (_intake == null) return 'Cette prise est introuvable.';
    try {
      return await action();
    } catch (_) {
      return "L'action n'a pas pu être enregistrée. Réessayez.";
    }
  }
}
