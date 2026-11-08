import '../../domain/entities/meal_instruction.dart';

/// Libellés affichés à l'utilisateur pour [MealInstruction].
extension MealInstructionLabel on MealInstruction {
  String get label => switch (this) {
    MealInstruction.none => 'Aucune consigne',
    MealInstruction.beforeMeal => 'Avant le repas',
    MealInstruction.duringMeal => 'Pendant le repas',
    MealInstruction.afterMeal => 'Après le repas',
  };
}
