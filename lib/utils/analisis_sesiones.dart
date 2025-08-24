import 'dart:math' as math;

class AnalisisSesiones {
  /// Resumen semanal
  static Map<String, dynamic> generarResumenSemanal(
      List<Map<String, dynamic>> sesiones) {
    final ahora = DateTime.now();
    final unaSemanaAtras = ahora.subtract(const Duration(days: 7));
    final sesionesSemana = sesiones.where((s) {
      final fecha = (s['date'] as DateTime? ?? DateTime.now());
      return fecha.isAfter(unaSemanaAtras) && fecha.isBefore(ahora);
    }).toList();
    return _generarResumen(sesionesSemana);
  }

  /// Resumen mensual
  static Map<String, dynamic> generarResumenMensual(
      List<Map<String, dynamic>> sesiones) {
    final ahora = DateTime.now();
    final unMesAtras = ahora.subtract(const Duration(days: 30));
    final sesionesMes = sesiones.where((s) {
      final fecha = (s['date'] as DateTime? ?? DateTime.now());
      return fecha.isAfter(unMesAtras) && fecha.isBefore(ahora);
    }).toList();
    return _generarResumen(sesionesMes);
  }

  /// Resumen global (todas las sesiones)
  static Map<String, dynamic> generarResumenGlobal(
      List<Map<String, dynamic>> sesiones) {
    return _generarResumen(sesiones);
  }

  /// Lógica centralizada para procesar sesiones
  static Map<String, dynamic> _generarResumen(
      List<Map<String, dynamic>> sesiones) {
    final resumen = <String, dynamic>{};
    final dias = <String, dynamic>{};
    int totalDias = 0;
    int diasCompletados = 0;
    final comentarios = <String>[];
    final ejerciciosIncompletos = <Map<String, dynamic>>[];

    int totalReps = 0;
    int totalEjercicios = 0;
    double sumaPesos = 0.0;
    Map<String, int> frecuenciaEjercicios = {};
    List<DateTime> fechasEntrenadas = [];

    for (final sesion in sesiones) {
      final String dia = sesion['day'] ?? 'Día desconocido';
      final List ejercicios = sesion['exercises'] ?? [];
      final String comentario = sesion['comentario_general'] ?? '';
      final fechaSesion = sesion['date'] as DateTime?;
      if (fechaSesion != null) fechasEntrenadas.add(fechaSesion);
      totalDias++;

      bool todosCompletados = ejercicios.every((e) => e['completed'] == true);
      if (todosCompletados) diasCompletados++;

      final detallesEjercicios = ejercicios.map((e) {
        // Volumen: peso_usado * repsRealizadas * series
        final peso = (e['peso_usado'] is num) ? e['peso_usado'] : 0.0;
        final reps = (e['repsRealizadas'] is num)
            ? (e['repsRealizadas'] as num).toInt()
            : 0;

        totalReps += reps;
        sumaPesos += peso;
        totalEjercicios++;
        final nombre = e['nombre'] ?? 'Ejercicio';
        frecuenciaEjercicios[nombre] = (frecuenciaEjercicios[nombre] ?? 0) + 1;
        return {
          'nombre': nombre,
          'grupoMuscular': e['grupoMuscular'],
          'repsPlanificadas': e['repsPlanificadas'],
          'repsRealizadas': reps,
          'pesoPlanificado': e['pesoPlanificado'],
          'pesoUsado': peso,
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
          'pesoPlanificado': e['pesoPlanificado'],
          'pesoUsado': e['peso_usado'],
        });
      });

      dias[dia] = {
        'completado': todosCompletados,
        'comentario': comentario.trim(),
        'ejercicios': detallesEjercicios,
      };
    }

    // Promedio de repeticiones por sesión
    final promedioReps = totalDias > 0 ? (totalReps / totalDias).round() : 0;
    // Promedio de peso usado por ejercicio
    final promedioPeso =
        totalEjercicios > 0 ? (sumaPesos / totalEjercicios).round() : 0;
    // Ejercicio más frecuente
    String ejercicioFrecuente = '';
    int maxFrecuencia = 0;
    frecuenciaEjercicios.forEach((ej, freq) {
      if (freq > maxFrecuencia) {
        ejercicioFrecuente = ej;
        maxFrecuencia = freq;
      }
    });
    // Racha máxima de días consecutivos entrenados
    int rachaMaxima = 0;
    if (fechasEntrenadas.isNotEmpty) {
      fechasEntrenadas.sort();
      int rachaActual = 1;
      for (int i = 1; i < fechasEntrenadas.length; i++) {
        final diff =
            fechasEntrenadas[i].difference(fechasEntrenadas[i - 1]).inDays;
        if (diff == 1) {
          rachaActual++;
        } else {
          rachaMaxima = math.max(rachaMaxima, rachaActual);
          rachaActual = 1;
        }
      }
      rachaMaxima = math.max(rachaMaxima, rachaActual);
    }

    resumen['total_dias'] = totalDias;
    resumen['dias_cumplidos'] = diasCompletados;
    resumen['porcentaje_cumplimiento'] =
        totalDias == 0 ? 0 : ((diasCompletados / totalDias) * 100).round();
    resumen['promedio_reps'] = promedioReps;
    resumen['promedio_peso'] = promedioPeso;
    resumen['ejercicio_frecuente'] = ejercicioFrecuente;
    resumen['racha_maxima'] = rachaMaxima;
    resumen['dias_entrenados'] = dias;
    resumen['comentarios'] = comentarios;
    resumen['ejercicios_incompletos'] = ejerciciosIncompletos;

    return resumen;
  }
}
