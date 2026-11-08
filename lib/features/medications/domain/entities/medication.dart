import 'dose_time.dart';
import 'meal_instruction.dart';

/// Un traitement, recopié de l'ordonnance.
///
/// La fréquence (prises par jour) n'est pas stockée : c'est le nombre
/// d'horaires dans [doseTimes].
class Medication {
  Medication({
    required this.id,
    required this.name,
    this.dosage = '',
    this.quantityPerIntake = 1,
    this.unit = 'comprimé',
    this.mealInstruction = MealInstruction.none,
    this.notes,
    required DateTime startDate,
    DateTime? endDate,
    required List<DoseTime> doseTimes,
    this.deletedAt,
  }) : startDate = dateOnly(startDate),
       endDate = endDate == null ? null : dateOnly(endDate),
       doseTimes = List.unmodifiable([...doseTimes]..sort());

  /// Identifiant ; vide pour un médicament pas encore enregistré.
  final String id;
  final String name;

  /// Tel qu'écrit sur la boîte, ex. « 500 mg ».
  final String dosage;

  /// Unités par prise : 2 comprimés à 08:00 = 1 prise, 2 comprimés.
  final double quantityPerIntake;

  /// « comprimé », « gélule », « ml »…
  final String unit;
  final MealInstruction mealInstruction;
  final String? notes;

  /// Premier jour du traitement (date seule).
  final DateTime startDate;

  /// Dernier jour du traitement inclus ; null = sans fin.
  final DateTime? endDate;

  /// Heures de prise, triées.
  final List<DoseTime> doseTimes;

  /// Moment de la suppression ; null s'il est toujours suivi. Un
  /// médicament supprimé compte encore pour les jours d'avant (historique).
  final DateTime? deletedAt;

  bool get isNew => id.isEmpty;

  /// Nombre de prises par jour.
  int get frequency => doseTimes.length;

  /// Le traitement est-il en cours le jour [day] ?
  /// Après la date de fin : plus de prise prévue, donc plus de rappel.
  bool isActiveOn(DateTime day) {
    final d = dateOnly(day);
    if (d.isBefore(startDate)) return false;
    final end = endDate;
    if (end != null && d.isAfter(end)) return false;
    final deleted = deletedAt;
    return deleted == null || !d.isAfter(dateOnly(deleted));
  }

  /// Une prise prévue à [at] fait-elle partie du traitement ? (Pas après
  /// sa suppression.)
  bool coversIntakeAt(DateTime at) =>
      isActiveOn(at) && (deletedAt == null || at.isBefore(deletedAt!));

  /// Nom affiché avec le dosage : « Paracétamol 500 mg ».
  String get displayName => dosage.isEmpty ? name : '$name $dosage';

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    double? quantityPerIntake,
    String? unit,
    MealInstruction? mealInstruction,
    String? Function()? notes,
    DateTime? startDate,
    DateTime? Function()? endDate,
    List<DoseTime>? doseTimes,
  }) => Medication(
    id: id ?? this.id,
    name: name ?? this.name,
    dosage: dosage ?? this.dosage,
    quantityPerIntake: quantityPerIntake ?? this.quantityPerIntake,
    unit: unit ?? this.unit,
    mealInstruction: mealInstruction ?? this.mealInstruction,
    notes: notes != null ? notes() : this.notes,
    startDate: startDate ?? this.startDate,
    endDate: endDate != null ? endDate() : this.endDate,
    doseTimes: doseTimes ?? this.doseTimes,
    deletedAt: deletedAt,
  );
}

/// Minuit du jour de [date] (heure locale).
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
