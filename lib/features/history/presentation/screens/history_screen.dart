import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/tab_page.dart';
import '../../domain/entities/history_day.dart';
import '../../domain/services/history_calculator.dart';
import '../mappers/history_labels.dart';
import '../viewmodels/history_view_model.dart';
import '../widgets/day_detail_sheet.dart';

/// Onglet « Historique » (maquette 8) : bilan des jours passés.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyViewModelProvider);
    final viewModel = ref.read(historyViewModelProvider.notifier);
    final summary = state.summary;

    return Scaffold(
      body: TabPage(
        title: 'Historique',
        children: [
          _PeriodSwitch(
            selected: state.period,
            onSelected: viewModel.selectPeriod,
          ),
          const SizedBox(height: 16),
          if (summary.value case final s?)
            ...s.days.isEmpty
                ? [const _Empty()]
                : [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _Stat(
                              label: 'Prises confirmées',
                              value: s.confirmed,
                              total: s.planned,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Stat(
                              label: 'Jours objectif eau',
                              value: s.waterGoalDays,
                              total: s.waterDays,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DayList(days: s.days),
                  ]
          else if (summary.hasError)
            const AppCard(child: Text("Impossible de charger l'historique."))
          else
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

/// « Cette semaine | Ce mois »
class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.selected, required this.onSelected});

  final HistoryPeriod selected;
  final ValueChanged<HistoryPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.neutralSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final (period, label) in const [
            (HistoryPeriod.week, 'Cette semaine'),
            (HistoryPeriod.month, 'Ce mois'),
          ])
            Expanded(
              child: Semantics(
                button: true,
                selected: period == selected,
                child: Material(
                  color: period == selected
                      ? AppColors.surface
                      : Colors.transparent,
                  elevation: period == selected ? 1 : 0,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onSelected(period),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          fontWeight: period == selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: period == selected
                              ? AppColors.text
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.total});

  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Semantics(
        // container : un élément par compteur pour les lecteurs d'écran.
        container: true,
        label: '$label : $value sur $total',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$value', style: text.headlineMedium),
                  TextSpan(
                    text: ' / $total',
                    style: text.bodyLarge?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.days});

  final List<HistoryDay> days;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, day) in days.indexed) ...[
            if (i > 0) const Divider(),
            InkWell(
              onTap: () => showDayDetailSheet(context, day),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.weekday(day.day),
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            Formatters.shortDate(day.day),
                            style: text.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (day.planned > 0)
                            Text(
                              HistoryLabels.intakes(day),
                              style: text.bodyLarge,
                            ),
                          if (day.summary.water case final w?)
                            Text(
                              '${w.glasses} / ${w.goal} verres',
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          // Sous le texte (et non à droite) : sur 360 dp,
                          // le bilan garde toute la largeur.
                          const SizedBox(height: 6),
                          _verdict(day.verdict),
                        ],
                      ),
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

  static Widget _verdict(DayVerdict v) {
    final (label, tone, icon) = HistoryLabels.verdict(v);
    return StatusBadge(label: label, tone: tone, icon: icon);
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Votre historique apparaîtra ici à partir de demain, jour après '
          'jour.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}
