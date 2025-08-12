import 'package:gymtrack_app/models/comidaPlanItem.dart';

class PlanAlimenticio {
  final String id;
  final String usuarioId;
  final DateTime fechaCreacion;
  final String objetivo;
  final bool esActual;
  final bool isVegetarian;
  final bool isVegan;
  final List<String> excludedFoods;
  final List<ComidaPlanItem> weeklyPlan;

  PlanAlimenticio({
    required this.id,
    required this.usuarioId,
    required this.fechaCreacion,
    required this.objetivo,
    required this.esActual,
    required this.isVegetarian,
    required this.isVegan,
    required this.excludedFoods,
    required this.weeklyPlan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'objetivo': objetivo,
      'esActual': esActual,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'excludedFoods': excludedFoods,
      'weeklyPlan': weeklyPlan.map((e) => e.toMap()).toList(),
    };
  }

  factory PlanAlimenticio.fromMap(Map<String, dynamic> map) {
    return PlanAlimenticio(
      id: map['id'],
      usuarioId: map['usuarioId'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      objetivo: map['objetivo'] ?? '',
      esActual: map['esActual'] ?? false,
      isVegetarian: map['isVegetarian'] ?? false,
      isVegan: map['isVegan'] ?? false,
      excludedFoods: List<String>.from(map['excludedFoods'] ?? []),
      weeklyPlan: (map['weeklyPlan'] as List<dynamic>)
          .map((e) => ComidaPlanItem.fromMap(e))
          .toList(),
    );
  }
}