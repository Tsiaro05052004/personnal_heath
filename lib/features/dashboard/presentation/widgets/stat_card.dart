import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

/// Petite carte « Médicaments 2 / 5 prises » ou « Eau 3 / 5 verres ».
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.softColor,
    required this.onTap,
    this.done,
    this.total,
    this.unit,
    this.emptyText,
  });

  final Widget icon;
  final String label;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  /// Compteur ; null → [emptyText] (ex. objectif pas encore défini).
  final int? done;
  final int? total;

  /// « prises », « verres »
  final String? unit;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = this.done;
    final total = this.total;
    final hasValue = done != null && total != null && total > 0;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Semantics(
        label: hasValue
            ? '$label : $done sur $total $unit'
            : '$label : $emptyText',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 22),
                  child: icon,
                ),
                const SizedBox(width: 8),
                Flexible(
                  // « Médicaments » reste sur une ligne, quitte à rétrécir.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: text.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (hasValue) ...[
              ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$done', style: text.headlineMedium),
                      TextSpan(
                        text: ' / $total $unit',
                        style: text.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (done / total).clamp(0, 1).toDouble(),
                  minHeight: 10,
                  color: color,
                  backgroundColor: softColor,
                ),
              ),
            ] else
              Text(emptyText ?? '', style: text.bodyLarge),
          ],
        ),
      ),
    );
  }
}
