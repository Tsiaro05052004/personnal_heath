import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/scheduled_intake.dart';
import '../../domain/services/intake_planner.dart';
import '../mappers/dose_labels.dart';

/// Ce que l'utilisateur a choisi dans la fiche d'une prise.
enum IntakeAction { confirm, markMissed }

/// Fiche du bas ouverte en touchant une prise : « J'ai pris mon
/// médicament » / « Je ne l'ai pas pris ».
Future<IntakeAction?> showIntakeActionsSheet(
  BuildContext context, {
  required ScheduledIntake intake,
  required bool canConfirm,
  required bool canMarkMissed,
}) {
  final text = Theme.of(context).textTheme;
  final medication = intake.medication;
  return showModalBottomSheet<IntakeAction>(
    context: context,
    showDragHandle: true,
    // Défilable : avec un texte agrandi, la fiche peut dépasser l'écran.
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${DoseLabels.hour(intake.scheduledAt)} · '
              '${medication.displayName}',
              style: text.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Prendre ${DoseLabels.summary(medication)}',
              style: text.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              intake.statusLabel,
              style: text.bodyLarge?.copyWith(
                color: intake.tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (medication.notes != null) ...[
              const SizedBox(height: 8),
              Text(medication.notes!, style: text.bodyMedium),
            ],
            const SizedBox(height: 20),
            if (canConfirm)
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("J'ai pris mon médicament"),
                onPressed: () => Navigator.pop(context, IntakeAction.confirm),
              ),
            if (canMarkMissed) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pop(context, IntakeAction.markMissed),
                child: const Text("Je ne l'ai pas pris"),
              ),
            ],
            if (!canConfirm && !canMarkMissed)
              Text(
                intake.state == IntakeState.upcoming
                    ? 'Vous pourrez confirmer cette prise à partir de '
                          '${_earliest(intake)}.'
                    : 'Rien à faire pour cette prise.',
                style: text.bodyLarge,
              ),
            const SizedBox(height: 20),
            const _NoMedicalAdvice(),
          ],
        ),
      ),
    ),
  );
}

String _earliest(ScheduledIntake intake) {
  final at = intake.scheduledAt.subtract(IntakePlanner.earlyConfirmWindow);
  return Formatters.hour(at.hour, at.minute);
}

/// Rappel affiché partout où une prise peut être manquée.
class _NoMedicalAdvice extends StatelessWidget {
  const _NoMedicalAdvice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neutralSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ne doublez jamais une dose oubliée. En cas de doute, '
              'demandez à votre médecin ou pharmacien.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
