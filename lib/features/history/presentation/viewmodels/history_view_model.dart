import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../di/history_providers.dart';
import '../../domain/entities/history_day.dart';
import '../../domain/services/history_calculator.dart';

/// Période choisie (gardée à part : le ViewModel est recréé à chaque tic
/// de l'horloge).
final _periodProvider = NotifierProvider<_Period, HistoryPeriod>(_Period.new);

class _Period extends Notifier<HistoryPeriod> {
  @override
  HistoryPeriod build() => HistoryPeriod.week;

  void select(HistoryPeriod p) => state = p;
}

class HistoryUiState {
  const HistoryUiState({required this.period, required this.summary});

  final HistoryPeriod period;
  final AsyncValue<HistoryPeriodSummary> summary;
}

final historyViewModelProvider =
    NotifierProvider<HistoryViewModel, HistoryUiState>(HistoryViewModel.new);

/// ViewModel de l'Historique (maquette 8).
class HistoryViewModel extends Notifier<HistoryUiState> {
  @override
  HistoryUiState build() {
    final now = ref.watch(clockProvider);
    final period = ref.watch(_periodProvider);
    final range = HistoryCalculator.range(period, now);

    final medications = ref.watch(historyMedicationsProvider);
    final intakeLogs = ref.watch(historyIntakeLogsProvider(range));
    final settings = ref.watch(historyWaterSettingsProvider);
    final waterLogs = ref.watch(historyWaterLogsProvider(range));
    final all = [medications, intakeLogs, settings, waterLogs];

    final AsyncValue<HistoryPeriodSummary> summary;
    if (all.every((a) => a.hasValue)) {
      summary = AsyncData(
        HistoryCalculator.build(
          period: period,
          now: now,
          medications: medications.requireValue,
          intakeLogs: intakeLogs.requireValue,
          waterSettings: settings.value,
          waterLogs: waterLogs.requireValue,
        ),
      );
    } else if (all.where((a) => a.hasError).firstOrNull case final failed?) {
      summary = AsyncError(failed.error!, failed.stackTrace!);
    } else {
      summary = const AsyncLoading();
    }
    return HistoryUiState(period: period, summary: summary);
  }

  void selectPeriod(HistoryPeriod period) =>
      ref.read(_periodProvider.notifier).select(period);
}
