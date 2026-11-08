import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/dashed_button.dart';
import '../../../../core/widgets/tab_page.dart';
import '../../domain/entities/scheduled_intake.dart';
import '../viewmodels/medication_list_ui_state.dart';
import '../viewmodels/medication_list_view_model.dart';
import '../widgets/day_strip.dart';
import '../widgets/intake_actions_sheet.dart';
import '../widgets/medication_day_card.dart';

/// Onglet « Mes médicaments » : prises du jour choisi, par médicament.
class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationListViewModelProvider);
    final viewModel = ref.read(medicationListViewModelProvider.notifier);
    final plan = state.plan;

    return Scaffold(
      body: TabPage(
        title: 'Mes médicaments',
        subtitle: switch (plan.value) {
          final p? when p.totalCount > 0 =>
            '${p.confirmedCount} ${p.confirmedCount > 1 ? 'prises confirmées' : 'prise confirmée'} '
                'sur ${p.totalCount} '
                '${state.isToday ? "aujourd'hui" : 'le ${Formatters.shortDate(state.selectedDay)}'}',
          _ => null,
        },
        children: [
          DayStrip(
            days: state.days,
            today: state.today,
            selected: state.selectedDay,
            onSelected: viewModel.selectDay,
          ),
          const SizedBox(height: 16),
          // On garde l'affichage précédent pendant un rechargement (tic de
          // l'horloge) pour éviter un clignotement.
          if (plan.value case final p?) ...[
            if (p.medications.isEmpty) _EmptyDay(isToday: state.isToday),
            for (final (index, day) in p.medications.indexed) ...[
              MedicationDayCard(
                day: day,
                colorIndex: index,
                canConfirm: state.canConfirm,
                onConfirm: (intake) => _confirm(context, viewModel, intake),
                onIntakeTap: (intake) =>
                    _openIntake(context, state, viewModel, intake),
                onEdit: () =>
                    context.push(AppRoutes.editMedication(day.medication.id)),
              ),
              const SizedBox(height: 16),
            ],
          ] else if (plan.hasError)
            const _LoadError()
          else
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          DashedButton(
            label: 'Ajouter un médicament',
            onPressed: () => context.push(AppRoutes.newMedication),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    MedicationListViewModel viewModel,
    ScheduledIntake intake,
  ) async {
    final error = await viewModel.confirmIntake(intake);
    if (context.mounted) {
      _snack(context, error ?? 'Prise de ${intake.medication.name} confirmée.');
    }
  }

  Future<void> _openIntake(
    BuildContext context,
    MedicationListUiState state,
    MedicationListViewModel viewModel,
    ScheduledIntake intake,
  ) async {
    final action = await showIntakeActionsSheet(
      context,
      intake: intake,
      canConfirm: state.canConfirm(intake),
      canMarkMissed: state.canMarkMissed(intake),
    );
    if (!context.mounted) return;
    switch (action) {
      case IntakeAction.confirm:
        await _confirm(context, viewModel, intake);
      case IntakeAction.markMissed:
        final error = await viewModel.markMissed(intake);
        if (context.mounted) {
          _snack(context, error ?? 'Prise notée comme non prise.');
        }
      case null:
        break;
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          children: [
            const Icon(
              Icons.event_available,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              isToday
                  ? "Aucune prise prévue aujourd'hui."
                  : 'Aucune prise prévue ce jour-là.',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoutez un médicament en recopiant votre ordonnance.',
              style: text.bodyLarge?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: AppCard(child: Text('Impossible de charger vos médicaments.')),
  );
}
