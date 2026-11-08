import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pill_icon.dart';
import '../../domain/entities/meal_instruction.dart';
import '../../domain/entities/scheduled_intake.dart';
import '../mappers/dose_labels.dart';
import '../mappers/meal_instruction_label.dart';
import '../viewmodels/intake_alarm_view_model.dart';

/// Écran d'alarme plein écran (maquette 7), ouvert depuis un rappel, même
/// téléphone verrouillé.
class IntakeAlarmScreen extends ConsumerStatefulWidget {
  const IntakeAlarmScreen({super.key, required this.target, this.action});

  final IntakeRef target;

  /// [AppRoutes.takenAction] : « J'ai pris » touché sur la notification.
  final String? action;

  @override
  ConsumerState<IntakeAlarmScreen> createState() => _IntakeAlarmScreenState();
}

class _IntakeAlarmScreenState extends ConsumerState<IntakeAlarmScreen> {
  bool _busy = false;
  bool _autoActionDone = false;

  NotifierProvider<IntakeAlarmViewModel, AsyncValue<IntakeAlarmUiState>>
  get _provider => intakeAlarmViewModelProvider(widget.target);
  IntakeAlarmViewModel get _vm => ref.read(_provider.notifier);

  @override
  Widget build(BuildContext context) {
    final AsyncValue<IntakeAlarmUiState> async = ref.watch(_provider);
    final state = async.value;

    // Bouton « J'ai pris » de la notification : on confirme directement.
    if (state != null &&
        !_autoActionDone &&
        widget.action == AppRoutes.takenAction) {
      _autoActionDone = true;
      if (state.canConfirm) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _do(_vm.confirm));
      }
    }

    final text = Theme.of(context).textTheme;
    final onDark = text.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: switch (state) {
          null when async.hasError => _Message(
            text: 'Impossible de charger cette prise.',
            onClose: _close,
          ),
          null => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          IntakeAlarmUiState(intake: null) => _Message(
            text: "Cette prise n'existe plus (médicament modifié ou supprimé).",
            onClose: _close,
          ),
          IntakeAlarmUiState(intake: final intake?) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              const _Bell(),
              const SizedBox(height: 16),
              Text(
                Formatters.clock(
                  intake.scheduledAt.hour,
                  intake.scheduledAt.minute,
                ),
                textAlign: TextAlign.center,
                style: onDark.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 64,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: Text(
                  _headline(intake),
                  textAlign: TextAlign.center,
                  style: onDark.headlineSmall,
                ),
              ),
              const SizedBox(height: 24),
              _MedicationCard(intake: intake),
              const SizedBox(height: 20),
              if (state.canConfirm)
                FilledButton.icon(
                  onPressed: _busy ? null : () => _do(_vm.confirm),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: const Size.fromHeight(68),
                  ),
                  icon: const Icon(Icons.check, size: 28),
                  label: const Text("J'ai pris mon médicament"),
                ),
              if (state.canSnooze) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _do(_vm.snooze),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(64),
                    side: const BorderSide(color: Colors.white70, width: 2),
                  ),
                  icon: const Icon(Icons.schedule, size: 26),
                  label: const Text('Me le rappeler dans 10 min'),
                ),
              ],
              if (state.canMarkMissed) ...[
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _busy ? null : () => _do(_vm.markMissed),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text("Je ne l'ai pas pris"),
                ),
              ],
              if (!state.canConfirm && !state.canSnooze) ...[
                const SizedBox(height: 14),
                _CloseButton(onClose: _close),
              ],
              const SizedBox(height: 20),
              const _NoDoubleDose(),
            ],
          ),
        },
      ),
    );
  }

  static String _headline(ScheduledIntake intake) => switch (intake.state) {
    IntakeState.taken => 'Déjà prise à ${DoseLabels.hour(intake.takenAt!)}',
    IntakeState.missed => 'Notée comme non prise',
    IntakeState.upcoming => 'Bientôt l’heure de votre médicament',
    _ => "C'est l'heure de votre médicament",
  };

  Future<void> _do(Future<String> Function() action) async {
    setState(() => _busy = true);
    final message = await action();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    _close();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.medications);
    }
  }
}

class _Bell extends StatelessWidget {
  const _Bell();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    ),
  );
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.intake});

  final ScheduledIntake intake;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final m = intake.medication;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const PillIcon(size: 32, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: text.headlineSmall),
                    if (m.dosage.isNotEmpty)
                      Text(
                        m.dosage,
                        style: text.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Prendre ${DoseLabels.quantity(m.quantityPerIntake, m.unit)}',
            style: text.titleLarge,
          ),
          if (m.mealInstruction != MealInstruction.none) ...[
            const SizedBox(height: 6),
            Text(
              m.mealInstruction.label,
              style: text.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
          ],
          if (m.notes != null) ...[
            const SizedBox(height: 6),
            Text(m.notes!, style: text.bodyLarge),
          ],
        ],
      ),
    );
  }
}

class _NoDoubleDose extends StatelessWidget {
  const _NoDoubleDose();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Ne doublez jamais une dose oubliée. En cas de doute, demandez '
            'à votre médecin ou pharmacien.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onClose,
    style: FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primaryDark,
      minimumSize: const Size.fromHeight(64),
    ),
    child: const Text('Fermer'),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onClose});

  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 24),
        _CloseButton(onClose: onClose),
      ],
    ),
  );
}
