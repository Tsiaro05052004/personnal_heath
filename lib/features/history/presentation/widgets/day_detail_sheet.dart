import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../hydration/presentation/mappers/water_texts.dart';
import '../../../medications/domain/services/intake_planner.dart';
import '../../../medications/presentation/mappers/dose_labels.dart';
import '../../domain/entities/history_day.dart';

/// Détail d'un jour passé : chaque prise et l'eau.
Future<void> showDayDetailSheet(BuildContext context, HistoryDay day) {
  final text = Theme.of(context).textTheme;
  final water = day.summary.water;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(Formatters.dayTitle(day.day), style: text.titleLarge),
            const SizedBox(height: 16),
            if (day.planned == 0)
              Text('Aucune prise prévue ce jour-là.', style: text.bodyLarge),
            for (final intake in day.summary.plan.intakes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        DoseLabels.hour(intake.scheduledAt),
                        style: text.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            intake.medication.displayName,
                            style: text.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          StatusBadge(
                            label: IntakePlanner.isLate(intake)
                                ? '${intake.statusLabel} (en retard)'
                                : intake.statusLabel,
                            tone: intake.tone,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (water != null) ...[
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.water_drop, color: AppColors.water),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Eau : ${water.glasses} sur '
                      '${WaterTexts.glasses(water.goal)}',
                      style: text.bodyLarge,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
