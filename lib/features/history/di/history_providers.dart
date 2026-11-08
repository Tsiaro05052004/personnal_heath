import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hydration/di/hydration_providers.dart';
import '../../hydration/domain/entities/water_log.dart';
import '../../hydration/domain/entities/water_settings.dart';
import '../../medications/di/medications_providers.dart';
import '../../medications/domain/entities/intake_log.dart';
import '../../medications/domain/entities/medication.dart';

/// L'historique n'a pas de données à lui : il lit celles des autres
/// features, par leurs use cases.
typedef DateRange = ({DateTime from, DateTime to});

/// Tous les médicaments, supprimés compris (ils comptent pour les jours
/// d'avant leur suppression).
final historyMedicationsProvider = StreamProvider.autoDispose<List<Medication>>(
  (ref) => ref.watch(watchMedicationsProvider)(includeDeleted: true),
);

final historyIntakeLogsProvider = StreamProvider.autoDispose
    .family<List<IntakeLog>, DateRange>(
      (ref, r) => ref.watch(watchIntakeLogsProvider)(r.from, r.to),
    );

final historyWaterSettingsProvider = StreamProvider.autoDispose<WaterSettings?>(
  (ref) => ref.watch(watchWaterSettingsProvider)(),
);

final historyWaterLogsProvider = StreamProvider.autoDispose
    .family<List<WaterLog>, DateRange>(
      (ref, r) => ref.watch(watchWaterLogsProvider)(r.from, r.to),
    );
