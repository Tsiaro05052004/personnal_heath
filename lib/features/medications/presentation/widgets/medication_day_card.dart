import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/pill_icon.dart';
import '../../domain/entities/day_plan.dart';
import '../../domain/entities/scheduled_intake.dart';
import '../mappers/dose_labels.dart';

/// Carte d'un médicament et de ses prises du jour (maquette « Mes
/// médicaments »).
class MedicationDayCard extends StatelessWidget {
  const MedicationDayCard({
    super.key,
    required this.day,
    required this.colorIndex,
    required this.canConfirm,
    required this.onConfirm,
    required this.onIntakeTap,
    required this.onEdit,
  });

  final MedicationDay day;
  final int colorIndex;
  final bool Function(ScheduledIntake) canConfirm;
  final ValueChanged<ScheduledIntake> onConfirm;
  final ValueChanged<ScheduledIntake> onIntakeTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final medication = day.medication;
    final (iconColor, iconBackground) =
        medicationIconColors[colorIndex % medicationIconColors.length];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: PillIcon(size: 30, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(medication.displayName, style: text.titleMedium),
                        Text(
                          DoseLabels.summary(medication),
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label:
                        '${day.confirmedCount} prises confirmées sur '
                        '${day.intakes.length}',
                    excludeSemantics: true,
                    child: Text(
                      '${day.confirmedCount} / ${day.intakes.length}',
                      style: text.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final intake in day.intakes)
            _IntakeRow(
              intake: intake,
              canConfirm: canConfirm(intake),
              onConfirm: () => onConfirm(intake),
              onTap: () => onIntakeTap(intake),
            ),
        ],
      ),
    );
  }
}

class _IntakeRow extends StatelessWidget {
  const _IntakeRow({
    required this.intake,
    required this.canConfirm,
    required this.onConfirm,
    required this.onTap,
  });

  final ScheduledIntake intake;
  final bool canConfirm;
  final VoidCallback onConfirm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final highlighted =
        intake.state == IntakeState.pending ||
        intake.state == IntakeState.unconfirmed;
    final statusColor = switch (intake.state) {
      IntakeState.upcoming => AppColors.textMuted,
      _ => intake.tone.foreground,
    };
    final icon = switch (intake.state) {
      IntakeState.taken => Icons.check,
      IntakeState.missed => Icons.close,
      IntakeState.pending || IntakeState.unconfirmed => Icons.schedule,
      IntakeState.upcoming => null,
    };

    return Material(
      color: highlighted ? AppColors.warningSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    DoseLabels.hour(intake.scheduledAt),
                    style: text.titleMedium,
                  ),
                ),
                // Avec le bouton « Confirmer », le fond orange suffit :
                // l'icône prendrait la place qui manque sur 360 dp.
                if (icon != null && !(canConfirm && highlighted)) ...[
                  Icon(icon, size: 22, color: statusColor),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    intake.statusLabel,
                    style: text.bodyLarge?.copyWith(
                      color: statusColor,
                      fontWeight: intake.state == IntakeState.upcoming
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                ),
                if (canConfirm && highlighted)
                  FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: text.labelLarge?.copyWith(fontSize: 18),
                    ),
                    child: const Text('Confirmer'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
