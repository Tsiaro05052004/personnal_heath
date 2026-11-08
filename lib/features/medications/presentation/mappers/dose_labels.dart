import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/dose_time.dart';
import '../../domain/entities/meal_instruction.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/scheduled_intake.dart';
import 'meal_instruction_label.dart';

/// Formes proposées dans le formulaire.
const doseUnits = ['comprimé', 'gélule', 'sachet', 'goutte', 'ml', 'cuillère'];

/// Libellés d'affichage des doses et des prises.
abstract final class DoseLabels {
  /// « 1 comprimé », « 2 comprimés », « 0,5 comprimé », « 5 ml ».
  static String quantity(double quantity, String unit) {
    final plural = quantity >= 2 && unit != 'ml';
    return '${Formatters.quantity(quantity)} $unit${plural ? 's' : ''}';
  }

  /// « 1 comprimé · après le repas · jusqu'au 12 nov. »
  static String summary(Medication m) => [
    quantity(m.quantityPerIntake, m.unit),
    if (m.mealInstruction != MealInstruction.none)
      m.mealInstruction.label.toLowerCase(),
    if (m.endDate != null) "jusqu'au ${Formatters.shortDate(m.endDate!)}",
  ].join(' · ');

  /// « 08h00 »
  static String hour(DateTime at) => Formatters.hour(at.hour, at.minute);

  /// « 08:00 »
  static String clock(DoseTime t) => Formatters.clock(t.hour, t.minute);

  /// « 1re prise · matin »
  static String doseTitle(int index, DoseTime time) =>
      '${index == 0 ? '1re' : '${index + 1}e'} prise · ${period(time)}';

  static String period(DoseTime time) => switch (time.hour) {
    < 11 => 'matin',
    < 15 => 'midi',
    < 18 => 'après-midi',
    _ => 'soir',
  };
}

/// Apparence d'un état de prise.
extension IntakeStateLabel on ScheduledIntake {
  String get statusLabel => switch (state) {
    IntakeState.taken =>
      takenAt == null ? 'Pris' : 'Pris à ${DoseLabels.hour(takenAt!)}',
    IntakeState.missed => 'Non pris',
    IntakeState.pending => 'En attente',
    IntakeState.unconfirmed => 'Non confirmée',
    IntakeState.upcoming => 'À venir',
  };

  BadgeTone get tone => switch (state) {
    IntakeState.taken => BadgeTone.success,
    IntakeState.missed => BadgeTone.danger,
    IntakeState.pending || IntakeState.unconfirmed => BadgeTone.warning,
    IntakeState.upcoming => BadgeTone.neutral,
  };
}

/// Couleurs d'icône alternées des cartes de médicaments.
const medicationIconColors = [
  (AppColors.primary, AppColors.primarySoft),
  (AppColors.accent, AppColors.accentSoft),
];
