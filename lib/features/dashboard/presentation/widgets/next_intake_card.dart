import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../medications/domain/entities/scheduled_intake.dart';
import '../mappers/dashboard_labels.dart';

/// Grande carte verte « Prochaine prise » (maquette 2), ou ce qu'il faut
/// faire quand il n'y a pas de prochaine prise.
class NextIntakeCard extends StatelessWidget {
  const NextIntakeCard.intake({
    super.key,
    required this.intake,
    required this.now,
    required this.summary,
    required this.onConfirm,
  }) : title = null,
       message = null,
       actionLabel = null,
       onAction = null;

  /// Carte sans prise : « Aucun médicament », « Plus de prise aujourd'hui ».
  const NextIntakeCard.message({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : intake = null,
       now = null,
       summary = null,
       onConfirm = null;

  final ScheduledIntake? intake;
  final DateTime? now;

  /// « 1 comprimé · après le repas »
  final String? summary;

  /// null si la prise ne peut pas encore être confirmée.
  final VoidCallback? onConfirm;

  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white);
    final intake = this.intake;
    final soft = Colors.white.withValues(alpha: 0.85);

    final children = intake == null
        ? <Widget>[
            Text(title!, style: text.headlineSmall),
            const SizedBox(height: 6),
            Text(message!, style: text.bodyLarge?.copyWith(color: soft)),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              _WhiteButton(label: actionLabel!, onPressed: onAction),
            ],
          ]
        : <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.schedule, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DashboardLabels.nextIntakeHeader(intake, now!),
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              Formatters.hour(
                intake.scheduledAt.hour,
                intake.scheduledAt.minute,
              ),
              style: text.displayMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(intake.medication.displayName, style: text.headlineSmall),
            const SizedBox(height: 2),
            Text(summary!, style: text.bodyLarge?.copyWith(color: soft)),
            const SizedBox(height: 20),
            if (onConfirm != null)
              _WhiteButton(
                label: 'Confirmer la prise',
                icon: Icons.check,
                onPressed: onConfirm,
              )
            else
              Text(
                'Vous pourrez la confirmer 30 min avant l’heure.',
                style: text.bodyMedium?.copyWith(color: soft),
              ),
          ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, this.icon, this.onPressed});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      minimumSize: const Size.fromHeight(64),
    );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 28),
            label: Text(label),
          );
  }
}
