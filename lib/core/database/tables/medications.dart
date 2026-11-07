import 'package:drift/drift.dart';

import '../../../features/medications/domain/entities/meal_instruction.dart';
import 'sync_columns.dart';

/// Un traitement. La fréquence n'est pas stockée : c'est le nombre
/// d'horaires dans [MedicationSchedules].
class Medications extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Dosage tel qu'écrit sur la boîte, ex. « 500 mg ».
  TextColumn get dosage => text().withDefault(const Constant(''))();

  /// Nombre d'unités par prise, ex. 2 comprimés = 1 prise.
  RealColumn get quantityPerIntake => real().withDefault(const Constant(1))();

  /// Unité, ex. « comprimé », « gélule », « ml ».
  TextColumn get unit => text().withDefault(const Constant('comprimé'))();

  TextColumn get mealInstruction => textEnum<MealInstruction>().withDefault(
    Constant(MealInstruction.none.name),
  )();

  /// Notes libres de l'utilisateur (recopiées de l'ordonnance).
  TextColumn get notes => text().nullable()();

  DateTimeColumn get startDate => dateTime()();

  /// Après cette date : plus d'horaires générés, donc plus de rappels.
  DateTimeColumn get endDate => dateTime().nullable()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();
}
