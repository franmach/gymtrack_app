/// Información nutricional detallada de un alimento o porción
class InfoNutricional {
  final double calories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;

  InfoNutricional({
    required this.calories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
  });

  factory InfoNutricional.fromMap(Map<String, dynamic> m) => InfoNutricional(
        calories: (m['calories'] as num).toDouble(),
        proteinGrams: (m['protein'] as num).toDouble(),
        carbGrams: (m['carbs'] as num).toDouble(),
        fatGrams: (m['fat'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'calories': calories,
        'protein': proteinGrams,
        'carbs': carbGrams,
        'fat': fatGrams,
      };
}
