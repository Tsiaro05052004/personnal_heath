import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/dose_time.dart';
import '../../domain/entities/meal_instruction.dart';
import '../../domain/services/medication_rules.dart';
import '../mappers/dose_labels.dart';
import '../mappers/meal_instruction_label.dart';
import '../mappers/medication_error_label.dart';
import '../viewmodels/medication_form_ui_state.dart';
import '../viewmodels/medication_form_view_model.dart';
import '../widgets/form_section.dart';
import '../widgets/reminder_permission_prompt.dart';

/// « Nouveau médicament » / « Modifier le médicament », en 3 étapes :
/// médicament → horaires → durée et consignes.
class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({super.key, this.medicationId});

  /// null pour un nouveau médicament.
  final String? medicationId;

  @override
  ConsumerState<MedicationFormScreen> createState() =>
      _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _notes = TextEditingController();
  bool _filled = false;

  AsyncNotifierProvider<MedicationFormViewModel, MedicationFormUiState>
  get _provider => medicationFormViewModelProvider(widget.medicationId);
  MedicationFormViewModel get _vm => ref.read(_provider.notifier);

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Remplit les champs texte une seule fois, quand le médicament à
  /// modifier est chargé.
  void _fillOnce(MedicationFormUiState s) {
    if (_filled) return;
    _filled = true;
    _name.text = s.name;
    _dosage.text = s.dosage;
    _notes.text = s.notes;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<MedicationFormUiState> async = ref.watch(_provider);
    final isEdit = widget.medicationId != null;
    final title = isEdit ? 'Modifier le médicament' : 'Nouveau médicament';

    final form = async.value;
    if (form == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: async.hasError
              ? const Text('Ce médicament est introuvable.')
              : const CircularProgressIndicator(),
        ),
      );
    }
    _fillOnce(form);

    return PopScope(
      // Le bouton retour du téléphone revient à l'étape précédente.
      canPop: form.step == FormStep.medication,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _vm.back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour',
            onPressed: _back,
          ),
          actions: [
            if (isEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Supprimer ce médicament',
                onPressed: _delete,
              ),
          ],
        ),
        body: ListView(
          // Une liste par étape : chaque étape s'ouvre en haut de page.
          key: ValueKey(form.step),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _StepHeader(form: form),
            const SizedBox(height: 16),
            ...switch (form.step) {
              FormStep.medication => _medicationStep(form),
              FormStep.schedule => _scheduleStep(form),
              FormStep.duration => _durationStep(form),
            },
            for (final error in form.errors) FormError(error.label),
          ],
        ),
        bottomNavigationBar: _BottomButtons(
          form: form,
          onBack: _back,
          onNext: _next,
        ),
      ),
    );
  }

  void _back() {
    if (!_vm.back()) context.pop();
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    final saved = await _vm.next();
    if (!saved || !mounted) return;
    await ensureReminderPermissions(context, ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_name.text.trim()} est enregistré.')),
    );
    context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce médicament ?'),
        content: const Text(
          'Ses rappels seront arrêtés. Les prises déjà enregistrées restent '
          "dans l'historique.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _vm.delete();
    if (mounted) context.pop();
  }

  // ---------------------------------------------------------------- Étape 1

  List<Widget> _medicationStep(MedicationFormUiState form) => [
    const FormQuestion('Nom du médicament'),
    TextField(
      controller: _name,
      onChanged: _vm.setName,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: const InputDecoration(hintText: 'Ex. Paracétamol'),
    ),
    const FormQuestion('Dosage (facultatif)'),
    TextField(
      controller: _dosage,
      onChanged: _vm.setDosage,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: const InputDecoration(hintText: 'Ex. 500 mg'),
    ),
    const FormQuestion('Sous quelle forme ?'),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final unit in doseUnits)
          SizedBox(
            width: 150,
            child: ChoiceButton(
              label: unit[0].toUpperCase() + unit.substring(1),
              selected: form.unit == unit,
              onTap: () => _vm.setUnit(unit),
            ),
          ),
      ],
    ),
    const FormHint("Recopiez exactement l'ordonnance de votre médecin."),
  ];

  // ---------------------------------------------------------------- Étape 2

  List<Widget> _scheduleStep(MedicationFormUiState form) => [
    _summary(form),
    const FormQuestion('Combien de fois par jour ?'),
    Row(
      children: [
        for (var n = 1; n <= MedicationRules.maxFrequency; n++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: n < MedicationRules.maxFrequency ? 10 : 0,
              ),
              child: Semantics(
                label: '$n fois par jour',
                excludeSemantics: true,
                child: ChoiceButton(
                  label: '$n×',
                  selected: form.frequency == n,
                  onTap: () => _vm.setFrequency(n),
                ),
              ),
            ),
          ),
      ],
    ),
    const FormQuestion('À quelle heure ?'),
    AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, time) in form.times.indexed) ...[
            if (i > 0) const Divider(),
            ListTile(
              minTileHeight: 64,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(
                DoseLabels.doseTitle(i, time),
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textMuted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DoseLabels.clock(time),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.schedule, color: AppColors.textMuted),
                ],
              ),
              onTap: () => _pickTime(i, time),
            ),
          ],
        ],
      ),
    ),
    const FormQuestion('Combien à chaque prise ?'),
    AppCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.remove,
            tooltip: 'Moins',
            onPressed: form.quantity > MedicationFormViewModel.minQuantity
                ? _vm.decrementQuantity
                : null,
          ),
          Expanded(
            child: Text(
              DoseLabels.quantity(form.quantity, form.unit),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            tooltip: 'Plus',
            onPressed: form.quantity < MedicationFormViewModel.maxQuantity
                ? _vm.incrementQuantity
                : null,
          ),
        ],
      ),
    ),
    const FormHint("Recopiez exactement l'ordonnance de votre médecin."),
  ];

  Future<void> _pickTime(int index, DoseTime current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Heure de la ${DoseLabels.doseTitle(index, current)}',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      _vm.setTime(index, DoseTime(picked.hour, picked.minute));
    }
  }

  // ---------------------------------------------------------------- Étape 3

  List<Widget> _durationStep(MedicationFormUiState form) => [
    _summary(form),
    const FormQuestion('Quand le prendre ?'),
    GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: [
        for (final meal in MealInstruction.values)
          ChoiceButton(
            label: meal.label,
            selected: form.mealInstruction == meal,
            onTap: () => _vm.setMealInstruction(meal),
          ),
      ],
    ),
    const FormQuestion('Début du traitement'),
    _DateButton(
      label: Formatters.longDate(form.startDate),
      onTap: () => _pickDate(form.startDate, _vm.setStartDate),
    ),
    const FormQuestion('Fin du traitement'),
    Row(
      children: [
        Expanded(
          child: ChoiceButton(
            label: 'Sans date de fin',
            selected: form.endDate == null,
            onTap: () => _vm.setEndDate(null),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ChoiceButton(
            label: form.endDate == null
                ? 'Choisir une date'
                : "Jusqu'au ${Formatters.shortDate(form.endDate!)}",
            selected: form.endDate != null,
            onTap: () => _pickDate(
              form.endDate ?? form.startDate.add(const Duration(days: 7)),
              _vm.setEndDate,
            ),
          ),
        ),
      ],
    ),
    const FormHint('Après la date de fin, les rappels s’arrêtent.'),
    const FormQuestion('Remarques (facultatif)'),
    TextField(
      controller: _notes,
      onChanged: _vm.setNotes,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: const InputDecoration(
        hintText: "Ex. consigne de l'ordonnance",
      ),
    ),
  ];

  Future<void> _pickDate(
    DateTime initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Widget _summary(MedicationFormUiState form) => MedicationSummaryCard(
    title: [
      form.name.trim(),
      if (form.dosage.trim().isNotEmpty) form.dosage.trim(),
    ].join(' · '),
    onEdit: () => _vm.goToStep(FormStep.medication),
  );
}

/// « Étape 2 sur 3 · Horaires » + barre de progression en 3 segments.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.form});

  final MedicationFormUiState form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          form.stepLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final step in FormStep.values)
              Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(
                    right: step == FormStep.values.last ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: step.index <= form.step.index
                        ? AppColors.primary
                        : AppColors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BottomButtons extends StatelessWidget {
  const _BottomButtons({
    required this.form,
    required this.onBack,
    required this.onNext,
  });

  final MedicationFormUiState form;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(
                    form.step == FormStep.medication ? 'Annuler' : 'Retour',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: form.saving ? null : onNext,
                  child: Text(form.isLastStep ? 'Enregistrer' : 'Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    icon: Icon(icon, size: 30),
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      minimumSize: const Size(64, 64),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: const BorderSide(color: AppColors.outline, width: 2),
    ),
  );
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        const Icon(Icons.calendar_today_outlined, color: AppColors.textMuted),
      ],
    ),
  );
}
