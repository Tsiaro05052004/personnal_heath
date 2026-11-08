import 'dart:async';

import '../entities/water_day.dart';
import '../entities/water_log.dart';
import '../entities/water_settings.dart';
import '../repositories/water_repository.dart';

/// L'eau du jour [day] ; null tant que l'objectif n'est pas défini.
class WatchWaterDay {
  const WatchWaterDay(this._repository);

  final WaterRepository _repository;

  Stream<WaterDay?> call(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);

    late StreamController<WaterDay?> controller;
    StreamSubscription<WaterSettings?>? settingsSub;
    StreamSubscription<List<WaterLog>>? logsSub;
    var settingsLoaded = false;
    WaterSettings? settings;
    List<WaterLog>? logs;

    void emit() {
      if (!settingsLoaded || logs == null) return;
      final s = settings;
      controller.add(
        s == null ? null : WaterDay(day: from, settings: s, logs: logs!),
      );
    }

    controller = StreamController<WaterDay?>(
      onListen: () {
        settingsSub = _repository.watchSettings().listen((value) {
          settingsLoaded = true;
          settings = value;
          emit();
        }, onError: controller.addError);
        logsSub = _repository.watchLogs(from, to).listen((value) {
          logs = value;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await settingsSub?.cancel();
        await logsSub?.cancel();
      },
    );
    return controller.stream;
  }
}
