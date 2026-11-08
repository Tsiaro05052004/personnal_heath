import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/tab_page.dart';
import '../../domain/entities/water_day.dart';
import '../mappers/water_texts.dart';
import '../viewmodels/hydration_view_model.dart';
import '../widgets/glass_icon.dart';
import '../widgets/water_ring.dart';

/// Onglet « Mon eau du jour » (maquette 5).
class HydrationScreen extends ConsumerWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationViewModelProvider);
    final viewModel = ref.read(hydrationViewModelProvider.notifier);
    final day = state.day;

    return Scaffold(
      body: TabPage(
        title: 'Mon eau du jour',
        trailing: day.value == null
            ? null
            : TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.water),
                onPressed: () => context.push(AppRoutes.waterGoal),
                child: const Text('Objectif'),
              ),
        children: [
          // Données précédentes gardées pendant un rechargement (horloge).
          if (day.hasValue)
            ...switch (day.value) {
              null => [const _SetupCard()],
              final d => _today(context, state, viewModel, d),
            }
          else if (day.hasError)
            const AppCard(child: Text("Impossible de charger l'eau du jour."))
          else
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  List<Widget> _today(
    BuildContext context,
    HydrationUiState state,
    HydrationViewModel viewModel,
    WaterDay day,
  ) {
    final text = Theme.of(context).textTheme;
    return [
      AppCard(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: Column(
          children: [
            Semantics(
              label: '${day.glasses} sur ${WaterTexts.glasses(day.goal)}',
              excludeSemantics: true,
              child: WaterRing(
                progress: day.progress,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${day.glasses} / ${day.goal}',
                      style: text.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      day.goal > 1 ? 'verres' : 'verre',
                      style: text.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${WaterTexts.ml(day.mlDrunk)} sur ${WaterTexts.ml(day.mlGoal)}',
              style: text.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ExcludeSemantics(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < day.goal; i++)
                    GlassIcon(filled: i < day.glasses),
                  if (day.glasses > day.goal)
                    Text(
                      '+${day.glasses - day.goal}',
                      style: text.titleLarge?.copyWith(color: AppColors.water),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () => _addGlass(context, viewModel),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.water,
          minimumSize: const Size.fromHeight(68),
        ),
        icon: const Icon(Icons.add, size: 30),
        label: const Text("J'ai bu un verre"),
      ),
      if (day.glasses > 0) ...[
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.water),
            onPressed: () => _undo(context, viewModel),
            child: const Text('Annuler le dernier verre'),
          ),
        ),
      ],
      const SizedBox(height: 16),
      _ReminderCard(day: day, nextReminder: state.nextReminder),
    ];
  }

  Future<void> _addGlass(
    BuildContext context,
    HydrationViewModel viewModel,
  ) async {
    final result = await viewModel.addGlass();
    if (!context.mounted) return;
    _snack(context, switch (result) {
      GlassResult.goalReached => "Bravo ! Objectif d'eau atteint aujourd'hui.",
      GlassResult.added => 'Verre ajouté.',
      GlassResult.failed => "Le verre n'a pas pu être enregistré.",
    });
  }

  Future<void> _undo(BuildContext context, HydrationViewModel viewModel) async {
    final done = await viewModel.undoLastGlass();
    if (context.mounted && done) _snack(context, 'Dernier verre annulé.');
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Encart bleu du bas : prochain rappel, ou félicitations.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.day, required this.nextReminder});

  final WaterDay day;
  final DateTime? nextReminder;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final next = nextReminder;
    final (IconData icon, String title, String body) = switch (day) {
      _ when day.goalReached => (
        Icons.check,
        'Objectif atteint, bravo !',
        'Continuez à boire selon votre soif.',
      ),
      _ when !day.settings.remindersEnabled => (
        Icons.notifications_off_outlined,
        'Rappels désactivés',
        'Vous pouvez les activer dans votre objectif.',
      ),
      _ when next != null => (
        Icons.notifications_none,
        'Prochain rappel à ${Formatters.hour(next.hour, next.minute)}',
        'Buvez un peu, régulièrement, tout au long de la journée.',
      ),
      _ => (
        Icons.notifications_none,
        "Plus de rappel aujourd'hui",
        'Buvez un peu, régulièrement, tout au long de la journée.',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.waterSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.water),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Premier lancement : l'objectif n'est pas encore défini.
class _SetupCard extends StatelessWidget {
  const _SetupCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.water_drop, size: 64, color: AppColors.water),
          const SizedBox(height: 16),
          Text(
            "Définissez votre objectif d'eau",
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez combien de verres boire par jour. Les rappels '
            'seront répartis entre votre réveil et votre coucher.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.push(AppRoutes.waterGoal),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.water,
              minimumSize: const Size.fromHeight(64),
            ),
            child: const Text('Définir mon objectif'),
          ),
        ],
      ),
    );
  }
}
