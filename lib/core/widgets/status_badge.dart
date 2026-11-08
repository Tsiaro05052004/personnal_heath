import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Couleur d'un badge de statut.
enum BadgeTone {
  success(AppColors.success, AppColors.successSoft),
  warning(AppColors.warning, AppColors.warningSoft),
  neutral(AppColors.neutral, AppColors.neutralSoft),
  danger(AppColors.danger, AppColors.dangerSoft);

  const BadgeTone(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

/// Pastille arrondie « ✓ Pris », « En attente », « À venir »…
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: tone.foreground),
            const SizedBox(width: 6),
          ],
          // Flexible : passe à la ligne si la place manque (grand texte).
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
