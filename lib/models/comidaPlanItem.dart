import 'package:gymtrack_app/models/comida.dart';

/// Detalle de una comida planificada para un día específico
class ComidaPlanItem {
  final String id;
  final String day;
  final Comida comida;
  final String portion;
  final String horario;
  final String tipo;

  ComidaPlanItem({
    required this.id,
    required this.day,
    required this.comida,
    required this.portion,
    required this.horario,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'comida': comida.toMap(),
      'portion': portion,
      'horario': horario,
      'tipo': tipo,
    };
  }

  factory ComidaPlanItem.fromMap(Map<String, dynamic> map) {
    return ComidaPlanItem(
      id: map['id'],
      day: map['day'],
      comida: Comida.fromMap(map['comida']),
      portion: map['portion'],
      horario: map['horario'],
      tipo: map['tipo'],
    );
  }
}