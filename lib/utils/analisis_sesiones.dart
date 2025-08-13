Map<String, dynamic> generarResumenMensual(List<Map<String, dynamic>> sesiones) {
  final resumen = <String, dynamic>{};
  final dias = <String, dynamic>{};
  int totalDias = 0;
  int diasCompletados = 0;
  final comentarios = <String>[];
  final ejerciciosIncompletos = <Map<String, dynamic>>[];

  for (final sesion in sesiones) {
    final String dia = sesion['day'] ?? 'Día desconocido';
    final List ejercicios = sesion['exercises'] ?? [];
    final String comentario = sesion['comentario_general'] ?? '';
    totalDias++;

    bool todosCompletados = ejercicios.every((e) => e['completed'] == true);
    if (todosCompletados) diasCompletados++;

    final detallesEjercicios = ejercicios.map((e) {
      return {
        'nombre': e['nombre'],
        'grupoMuscular': e['grupoMuscular'],
        'repsPlanificadas': e['repsPlanificadas'],
        'repsRealizadas': e['repsRealizadas'],
        'completado': e['completed'] == true,
        'incompleto': e['incomplete'] == true,
      };
    }).toList();

    if (comentario.trim().isNotEmpty) {
      comentarios.add(comentario.trim());
    }

    ejercicios.where((e) => e['incomplete'] == true).forEach((e) {
      ejerciciosIncompletos.add({
        'nombre': e['nombre'],
        'grupoMuscular': e['grupoMuscular'],
        'dia': dia,
        'repsRealizadas': e['repsRealizadas'],
        'repsPlanificadas': e['repsPlanificadas'],
      });
    });

    dias[dia] = {
      'completado': todosCompletados,
      'comentario': comentario.trim(),
      'ejercicios': detallesEjercicios,
    };
  }

  resumen['total_dias'] = totalDias;
  resumen['dias_cumplidos'] = diasCompletados;
  resumen['porcentaje_cumplimiento'] = totalDias == 0 ? 0 : ((diasCompletados / totalDias) * 100).round();
  resumen['dias_entrenados'] = dias;
  resumen['comentarios'] = comentarios;
  resumen['ejercicios_incompletos'] = ejerciciosIncompletos;

  return resumen;
}
