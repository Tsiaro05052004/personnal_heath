import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/services/water_rules.dart';
import '../mappers/water_texts.dart';
import '../viewmodels/water_goal_view_model.dart';

/// « Mon objectif d'eau » : verres par jour, taille du verre, heures de
/// réveil et de coucher, rappels.
class WaterGoalScreen extends ConsumerWidget {
  const WaterGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(waterGoalViewModelProvider);
    final vm = ref.read(waterGoalViewModelProvider.notifier);
    final form = async.value;

    return Scaffold(
      appBar: AppBar(title: const Text("Mon objectif d'eau")),
      body: form == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                const FormQuestion('Combien de verres par jour ?'),
                QuantityStepper(
                  label: WaterTexts.glasses(form.settings.goalGlasses),
                  subtitle: 'soit ${WaterTexts.ml(form.settings.goalMl)}',
                  onDecrement: form.settings.goalGlasses > WaterRules.minGoal
                      ? () => vm.setGoal(form.settings.goalGlasses - 1)
                      : null,
                  onIncrement: form.settings.goalGlasses < WaterRules.maxGoal
                      ? () => vm.setGoal(form.settings.goalGlasses + 1)
                      : null,
                ),
                const FormHint(
                  'Choisissez un objectif adapté à vos besoins. En cas de '
                  'doute, demandez conseil à votre médecin.',
                ),
                const FormQuestion('Taille de vos verres'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final ml in WaterRules.glassSizes)
                      SizedBox(
                        width: 100,
                        child: ChoiceButton(
                          label: '$ml ml',
                          selected: form.settings.mlPerGlass == ml,
                          color: AppColors.water,
                          onTap: () => vm.setGlassSize(ml),
                        ),
                      ),
                  ],
                ),
                const FormQuestion('Vos horaires'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _TimeRow(
                        label: 'Réveil',
                        minute: form.settings.wakeMinute,
                        onPicked: vm.setWake,
                      ),
                      const Divider(),
                      _TimeRow(
                        label: 'Coucher',
                        minute: form.settings.sleepMinute,
                        onPicked: vm.setSleep,
                      ),
                    ],
                  ),
                ),
                const FormHint(
                  'Les rappels sont répartis entre ces deux heures.',
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: SwitchListTile(
                    value: form.settings.remindersEnabled,
                    onChanged: vm.setReminders,
                    activeThumbColor: AppColors.water,
                    title: Text(
                      'Me rappeler de boire',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: const Text(
                      'Un rappel de temps en temps, jamais beaucoup '
                      "d'un coup.",
                    ),
                  ),
                ),
                for (final error in form.errors) FormError(_label(error)),
              ],
            ),
      bottomNavigationBar: form == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.water,
                  ),
                  onPressed: form.saving
                      ? null
                      : () async {
                          if (await vm.save() && context.mounted) {
                            context.pop();
                          }
                        },
                  child: const Text('Enregistrer'),
                ),
              ),
            ),
    );
  }

  static String _label(WaterSettingsError error) => switch (error) {
    WaterSettingsError.invalidGoal =>
      "L'objectif doit être entre ${WaterRules.minGoal} et "
          '${WaterRules.maxGoal} verres.',
    WaterSettingsError.invalidGlassSize => 'Choisissez une taille de verre.',
    WaterSettingsError.sleepBeforeWake =>
      "L'heure du coucher doit être au moins 2 h après celle du réveil.",
  };
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minute,
    required this.onPicked,
  });

  final String label;
  final int minute;
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 64,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Formatters.clock(minute ~/ 60, minute % 60),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(width: 10),
        const Icon(Icons.schedule, color: AppColors.textMuted),
      ],
    ),
    onTap: () async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
        helpText: 'Heure du ${label.toLowerCase()}',
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (picked != null) onPicked(picked.hour * 60 + picked.minute);
    },
  );
}
