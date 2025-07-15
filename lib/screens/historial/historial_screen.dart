import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gymtrack_app/models/entrenamiento.dart';
import 'package:fl_chart/fl_chart.dart';

/// Pantalla que muestra el historial de entrenamientos del usuario.
/// Cada ítem puede expandirse para mostrar los ejercicios realizados.
class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  /// Simula una lista de entrenamientos con ejercicios incluidos
  List<Entrenamiento> obtenerEntrenamientosSimulados() {
    return [
      Entrenamiento(
        id: 'ent1',
        usuarioId: 'uid_angel',
        rutinaId: 'rutina1',
        fecha: DateTime.now().subtract(const Duration(days: 1)), // Ayer
        duracion: 60,
        estado: 'completo',
        ejercicios: [
          {'nombre': 'Sentadillas', 'reps': 12, 'hecho': true},
          {'nombre': 'Press banca', 'reps': 10, 'hecho': true},
        ],
      ),
      Entrenamiento(
        id: 'ent2',
        usuarioId: 'uid_angel',
        rutinaId: 'rutina1',
        fecha: DateTime.now().subtract(const Duration(days: 3)), // Hace 3 días
        duracion: 45,
        estado: 'incompleto',
        ejercicios: [
          {'nombre': 'Remo', 'reps': 10, 'hecho': false},
          {'nombre': 'Bicicleta fija', 'reps': 0, 'hecho': false},
        ],
      ),
      Entrenamiento(
        id: 'ent3',
        usuarioId: 'uid_angel',
        rutinaId: 'rutina1',
        fecha: DateTime.now().subtract(const Duration(days: 6)), // Hace 6 días
        duracion: 50,
        estado: 'completo',
        ejercicios: [
          {'nombre': 'Peso muerto', 'reps': 8, 'hecho': true},
          {'nombre': 'Dominadas', 'reps': 6, 'hecho': true},
        ],
      ),
      Entrenamiento(
        id: 'ent4',
        usuarioId: 'uid_angel',
        rutinaId: 'rutina1',
        fecha: DateTime.now()
            .subtract(const Duration(days: 7)), // Fuera de la semana
        duracion: 30,
        estado: 'completo',
        ejercicios: [
          {'nombre': 'Abdominales', 'reps': 20, 'hecho': true},
          {'nombre': 'Soga', 'reps': 0, 'hecho': true},
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final entrenamientos = obtenerEntrenamientosSimulados();
    final formatoFecha = DateFormat('dd/MM/yyyy');

    // Filtrar sesiones dentro de la última semana
    final ahora = DateTime.now();
    final unaSemanaAtras = ahora.subtract(const Duration(days: 7));
    final entrenamientosDeLaSemana = entrenamientos.where((e) {
      return e.fecha.isAfter(unaSemanaAtras) && e.fecha.isBefore(ahora);
    }).toList();

    // Calcular días entrenados (únicas fechas)
    final diasEntrenados = entrenamientosDeLaSemana
        .map((e) => formatoFecha.format(e.fecha))
        .toSet()
        .length;

    // Calcular porcentaje de cumplimiento
    final completas =
        entrenamientosDeLaSemana.where((e) => e.estado == 'completo').length;
    final total = entrenamientosDeLaSemana.length;
    final porcentajeCumplido =
        total > 0 ? (completas / total * 100).round() : 0;

    // Calcular progreso general
    final totalSesiones = entrenamientos.length;
    final totalCompletas =
        entrenamientos.where((e) => e.estado == 'completo').length;

// Agrupar por semana (lunes a domingo)
    Map<int, int> sesionesPorSemana = {};
    for (var ent in entrenamientos) {
      // Usamos la semana del año como clave
      int week;
      try {
        week = int.parse(DateFormat('w').format(ent.fecha));
      } catch (e) {
        week = 0; // Valor neutro si falla la conversión
      }
      sesionesPorSemana[week] = (sesionesPorSemana[week] ?? 0) + 1;
    }
    final mejorSemana = sesionesPorSemana.values.isNotEmpty
        ? sesionesPorSemana.values.reduce((a, b) => a > b ? a : b)
        : 0;

    // Calcular racha de días consecutivos entrenando
    final fechasOrdenadas = entrenamientos
        .map((e) => DateUtils.dateOnly(e.fecha))
        .toSet()
        .toList()
      ..sort();

    int rachaMaxima = 0;
    int rachaActual = 1;

    for (int i = 1; i < fechasOrdenadas.length; i++) {
      final anterior = fechasOrdenadas[i - 1];
      final actual = fechasOrdenadas[i];

      if (actual.difference(anterior).inDays == 1) {
        rachaActual += 1;
        rachaMaxima = rachaActual > rachaMaxima ? rachaActual : rachaMaxima;
      } else {
        rachaActual = 1;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Entrenamientos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de resumen semanal
          Text(
            'Resumen semanal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Días entrenados: $diasEntrenados'),
          Text('Porcentaje cumplido: $porcentajeCumplido%'),

          // Título del gráfico
          const SizedBox(height: 16),
          Text(
            'Progreso por ejercicio (última semana)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const Divider(height: 32),

          // Gráfico de barras
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = [
                          'Sent.',
                          'Press',
                          'Remo',
                          'Bici',
                          'Peso',
                          'Dom.',
                          'Abd.',
                          'Soga'
                        ];
                        return Text(labels[value.toInt()],
                            style: const TextStyle(fontSize: 10));
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        // Mostrar solo valores enteros
                        if (value % 1 == 0) {
                          return Text(value.toInt().toString(),
                              style: const TextStyle(fontSize: 10));
                        }
                        return const SizedBox
                            .shrink(); // Oculta valores no enteros
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                      x: 0, barRods: [BarChartRodData(toY: 36, width: 12)]),
                  BarChartGroupData(
                      x: 1, barRods: [BarChartRodData(toY: 30, width: 12)]),
                  BarChartGroupData(
                      x: 2, barRods: [BarChartRodData(toY: 10, width: 12)]),
                  BarChartGroupData(
                      x: 3, barRods: [BarChartRodData(toY: 0, width: 12)]),
                  BarChartGroupData(
                      x: 4, barRods: [BarChartRodData(toY: 8, width: 12)]),
                  BarChartGroupData(
                      x: 5, barRods: [BarChartRodData(toY: 6, width: 12)]),
                  BarChartGroupData(
                      x: 6, barRods: [BarChartRodData(toY: 20, width: 12)]),
                  BarChartGroupData(
                      x: 7, barRods: [BarChartRodData(toY: 0, width: 12)]),
                ],
              ),
            ),
          ),

          const Divider(height: 32),
          Text(
            'Sesiones de entrenamiento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          // Lista de sesiones expandibles
          ...entrenamientos.map((ent) {
            return ExpansionTile(
              title: Text('Fecha: ${formatoFecha.format(ent.fecha)}'),
              subtitle:
                  Text('Duración: ${ent.duracion} min - Estado: ${ent.estado}'),
              leading: Icon(
                ent.estado == 'completo' ? Icons.check_circle : Icons.error,
                color: ent.estado == 'completo' ? Colors.green : Colors.red,
              ),
              children: [
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Text(
                    'Ejercicios realizados:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...ent.ejercicios.map((ej) => ListTile(
                      title: Text(ej['nombre']),
                      subtitle: Text('Repeticiones: ${ej['reps']}'),
                      trailing: Icon(
                        ej['hecho'] ? Icons.check : Icons.close,
                        color: ej['hecho'] ? Colors.green : Colors.red,
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            );
          }),
          const SizedBox(height: 24),
          Text(
            'Progreso general',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Total de sesiones: $totalSesiones'),
          Text('Sesiones completadas: $totalCompletas'),
          Text('Mejor semana: $mejorSemana sesiones'),
          Text('Racha más larga de días seguidos entrenando: $rachaMaxima'),
        ],
      ),
    );
  }
}
