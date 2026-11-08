import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

/// Bandeau des 5 jours (« Ven 6 · Sam 7 · Auj. 8 · Lun 9 · Mar 10 »).
class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.days,
    required this.today,
    required this.selected,
    required this.onSelected,
  });

  final List<DateTime> days;
  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _DayChip(
                weekday: day == today ? 'Auj.' : Formatters.shortWeekday(day),
                number: '${day.day}',
                selected: day == selected,
                semantics: day == today
                    ? "Aujourd'hui"
                    : Formatters.dayTitle(day),
                onTap: () => onSelected(day),
                text: text,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.weekday,
    required this.number,
    required this.selected,
    required this.semantics,
    required this.onTap,
    required this.text,
  });

  final String weekday;
  final String number;
  final bool selected;
  final String semantics;
  final VoidCallback onTap;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.text;
    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text(weekday, style: text.bodySmall?.copyWith(color: fg)),
                Text(number, style: text.titleLarge?.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
