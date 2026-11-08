import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/pill_icon.dart';
import '../../../../core/widgets/profile_button.dart';
import '../../../../core/widgets/tab_page.dart';
import '../../../medications/domain/entities/scheduled_intake.dart';
import '../../../medications/presentation/mappers/dose_labels.dart';
import '../../domain/entities/daily_summary.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../widgets/next_intake_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/today_list.dart';

/// Accueil (maquette 2) : le résumé de la journée.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final viewModel = ref.read(dashboardViewModelProvider.notifier);
    final summary = state.summary;

    return Scaffold(
      body: TabPage(
        title: switch (state.displayName) {
          final name? when name.isNotEmpty => 'Bonjour, $name',
          _ => 'Bonjour',
        },
        overline: Formatters.dayTitle(state.now),
        trailing: const ProfileButton(),
        children: [
          if (summary.value case final s?)
            ..._content(context, state, viewModel, s)
          else if (summary.hasError)
            const AppCard(child: Text('Impossible de charger votre journée.'))
          else
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    DashboardUiState state,
    DashboardViewModel viewModel,
    DailySummary s,
  ) {
    final text = Theme.of(context).textTheme;
    final water = s.water;
    return [
      _nextIntakeCard(context, state, viewModel, s),
      const SizedBox(height: 16),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatCard(
                icon: const PillIcon(),
                label: 'Médicaments',
                color: AppColors.primary,
                softColor: AppColors.primarySoft,
                done: s.hasMedications ? s.plan.confirmedCount : null,
                total: s.hasMedications ? s.plan.totalCount : null,
                unit: 'prises',
                emptyText: 'Aucune prise',
                onTap: () => context.go(AppRoutes.medications),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: const Icon(Icons.water_drop_outlined),
                label: 'Eau',
                color: AppColors.water,
                softColor: AppColors.waterSoft,
                done: water?.glasses,
                total: water?.goal,
                unit: 'verres',
                emptyText: 'Définir un objectif',
                onTap: () => context.go(AppRoutes.hydration),
              ),
            ),
          ],
        ),
      ),
      if (s.groups.isNotEmpty) ...[
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text("Aujourd'hui", style: text.headlineSmall),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.medications),
              child: const Text('Tout voir'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TodayList(
          groups: s.groups,
          onTap: () => context.go(AppRoutes.medications),
        ),
      ],
    ];
  }

  Widget _nextIntakeCard(
    BuildContext context,
    DashboardUiState state,
    DashboardViewModel viewModel,
    DailySummary s,
  ) {
    final next = s.nextIntake;
    if (next != null) {
      return NextIntakeCard.intake(
        intake: next,
        now: state.now,
        summary: DoseLabels.summary(next.medication),
        onConfirm: state.canConfirm(next)
            ? () => _confirm(context, viewModel, next)
            : null,
      );
    }
    if (!s.hasMedications) {
      return NextIntakeCard.message(
        title: 'Aucun médicament',
        message: 'Ajoutez votre traitement pour recevoir des rappels.',
        actionLabel: 'Ajouter un médicament',
        onAction: () => context.push(AppRoutes.newMedication),
      );
    }
    final unconfirmed = s.plan.intakes
        .where((i) => i.state == IntakeState.unconfirmed)
        .length;
    return NextIntakeCard.message(
      title: "Plus de prise prévue aujourd'hui",
      message: unconfirmed == 0
          ? 'Toutes vos prises du jour sont faites.'
          : unconfirmed == 1
          ? '1 prise n’a pas été confirmée.'
          : '$unconfirmed prises n’ont pas été confirmées.',
      actionLabel: unconfirmed == 0 ? null : 'Voir mes prises',
      onAction: () => context.go(AppRoutes.medications),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    DashboardViewModel viewModel,
    ScheduledIntake intake,
  ) async {
    final error = await viewModel.confirm(intake);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Prise de ${intake.medication.name} confirmée.',
          ),
        ),
      );
  }
}
