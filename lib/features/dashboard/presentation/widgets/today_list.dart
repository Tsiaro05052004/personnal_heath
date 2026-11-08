import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/intake_group.dart';
import '../mappers/dashboard_labels.dart';

/// Liste « Aujourd'hui » : une ligne par heure de prise.
class TodayList extends StatelessWidget {
  const TodayList({super.key, required this.groups, required this.onTap});

  final List<IntakeGroup> groups;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, group) in groups.indexed) ...[
            if (i > 0) const Divider(),
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        Formatters.hour(group.at.hour, group.at.minute),
                        style: text.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        group.medicationNames.join(', '),
                        style: text.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Largeur naturelle du badge ; au-delà, il passe à la
                    // ligne entre deux mots (« Non / confirmée »).
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: _badge(group),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _badge(IntakeGroup group) {
    final (label, tone, icon) = DashboardLabels.groupBadge(group.state);
    return StatusBadge(label: label, tone: tone, icon: icon);
  }
}
