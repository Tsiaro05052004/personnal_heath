/// Consigne de prise par rapport au repas.
enum MealInstruction {
  none('Aucune consigne'),
  beforeMeal('Avant le repas'),
  duringMeal('Pendant le repas'),
  afterMeal('Après le repas');

  const MealInstruction(this.label);

  final String label;
}
