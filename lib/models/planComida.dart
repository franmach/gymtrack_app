class PlanComida {
  final String planId;
  final String comidaId;

  PlanComida({
    required this.planId,
    required this.comidaId,
  });

  factory PlanComida.fromMap(Map<String, dynamic> map) => PlanComida(
        planId: map['plan_id'] as String,
        comidaId: map['comida_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        'plan_id': planId,
        'comida_id': comidaId,
      };
}