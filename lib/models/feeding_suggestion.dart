/*
 * Modelo para almacenar el resultado de la calculadora de alimentación.
 */
class FeedingSuggestion {
  final int totalGramsPerDay; // Gramos totales recomendados por día
  final int mealsPerDay;      // Número de comidas recomendadas por día
  final String message;       // Mensaje de consejo/explicación

  FeedingSuggestion({
    required this.totalGramsPerDay,
    required this.mealsPerDay,
    required this.message,
  });

  // Calcula los gramos por comida, redondeando
  int get gramsPerMeal {
    if (mealsPerDay == 0) return 0;
    return (totalGramsPerDay / mealsPerDay).round();
  }
}