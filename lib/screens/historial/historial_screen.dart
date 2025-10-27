// 📄 GIMNASIO_SCREEN.DART – Corregido por Ángel y ChatGPT
// Incluye:
// - Mejora visual en el gráfico de historial (fl_chart)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:gymtrack_app/widgets/charts/grafico_linea.dart';
import 'package:gymtrack_app/widgets/charts/grafico_torta.dart';
import 'package:gymtrack_app/widgets/charts/grafico_barras.dart';
import 'package:gymtrack_app/widgets/charts/grafico_volumen.dart';
import 'package:gymtrack_app/widgets/charts/grafico_prs.dart';
import 'package:gymtrack_app/utils/analisis_sesiones.dart';
import 'dart:math';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  int tipoGrafica = 0; // 0: Progreso, 1: Distribución, 2: Comparativa, 3: Volumen, 4: PRs
  List<Map<String, dynamic>> sesiones = [];
  bool cargando = true;
  final formatoFecha = DateFormat('dd/MM/yyyy');
  int vistaResumen = 0; // 0: semanal, 1: mensual, 2: global
  Map<String, dynamic> resumen = {};
  List<Map<String, dynamic>> sesionesFiltradas = [];

  @override
  void initState() {
    super.initState();
    cargarSesiones();
  }

  Future<void> cargarSesiones() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sesiones')
          .where('uid', isEqualTo: uid)
          .orderBy('date', descending: true)
          .get();

      sesiones = snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data['date'] == null || data['exercises'] == null) return null;
            // Convertir Timestamp a DateTime para análisis
            data['date'] = (data['date'] is Timestamp)
                ? (data['date'] as Timestamp).toDate()
                : data['date'];
            return data;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
  _actualizarResumen();
    } catch (e, st) {
      print('Error al cargar sesiones: $e');
      print(st);
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  void _actualizarResumen() {
    DateTime ahora = DateTime.now();
    if (vistaResumen == 0) {
      resumen = AnalisisSesiones.generarResumenSemanal(sesiones);
      DateTime unaSemanaAtras = ahora.subtract(const Duration(days: 7));
      sesionesFiltradas = sesiones.where((s) {
        final fecha = (s['date'] as DateTime? ?? ahora);
        return fecha.isAfter(unaSemanaAtras) && fecha.isBefore(ahora);
      }).toList();
    } else if (vistaResumen == 1) {
      resumen = AnalisisSesiones.generarResumenMensual(sesiones);
      DateTime unMesAtras = ahora.subtract(const Duration(days: 30));
      sesionesFiltradas = sesiones.where((s) {
        final fecha = (s['date'] as DateTime? ?? ahora);
        return fecha.isAfter(unMesAtras) && fecha.isBefore(ahora);
      }).toList();
    } else {
      resumen = AnalisisSesiones.generarResumenGlobal(sesiones);
      sesionesFiltradas = List.from(sesiones);
    }
    setState(() {});
  }

  int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDayOfYear);
    return ((diff.inDays + firstDayOfYear.weekday) / 7).floor();
  }
  Widget _buildGraficaDinamica() {
    // Progreso (línea): sesiones en el tiempo
    if (tipoGrafica == 0) {
      // Etiquetas: fechas, Datos: total reps por sesión
      final etiquetas = sesionesFiltradas.map((s) => formatoFecha.format(s['date'] as DateTime)).toList();
      final datos = sesionesFiltradas.map((s) {
        final ejercicios = s['exercises'] as List<dynamic>? ?? [];
        return ejercicios.fold<double>(0, (sum, e) => sum + (e['repsRealizadas'] is num ? e['repsRealizadas'] : 0));
      }).toList();
      return GraficoLinea(etiquetas: List<String>.from(etiquetas), datos: List<double>.from(datos), titulo: 'Progreso de repeticiones');
    }
    // Distribución (torta): por grupo muscular
    if (tipoGrafica == 1) {
      final Map<String, double> grupos = {};
      for (var s in sesionesFiltradas) {
        final ejercicios = s['exercises'] as List<dynamic>? ?? [];
        for (var e in ejercicios) {
          final grupo = e['grupoMuscular'] ?? 'Otro';
          grupos[grupo] = (grupos[grupo] ?? 0) + (e['repsRealizadas'] is num ? e['repsRealizadas'].toDouble() : 0.0);
        }
      }
      return GraficoTorta(data: grupos, titulo: 'Distribución por grupo muscular');
    }
    // Comparativa (barras): comparar volumen entre períodos
    if (tipoGrafica == 2) {
      // Etiquetas: fechas, Datos: volumen total por sesión
      final etiquetas = sesionesFiltradas.map((s) => formatoFecha.format(s['date'] as DateTime)).toList();
      final datos = sesionesFiltradas.map((s) {
        final ejercicios = s['exercises'] as List<dynamic>? ?? [];
        return ejercicios.fold<double>(0, (sum, e) {
          final peso = (e['peso_usado'] is num) ? e['peso_usado'] : 0.0;
          final reps = (e['repsRealizadas'] is num) ? e['repsRealizadas'] : 0.0;
          final series = (e['series'] is num) ? e['series'] : 1.0;
          return sum + (peso * reps * series);
        });
      }).toList();
      return GraficoBarras(etiquetas: List<String>.from(etiquetas), datos: List<double>.from(datos), titulo: 'Volumen por sesión');
    }
    // Volumen (línea): volumen total levantado por día
    if (tipoGrafica == 3) {
      final etiquetas = sesionesFiltradas.map((s) => formatoFecha.format(s['date'] as DateTime)).toList();
      final datos = sesionesFiltradas.map((s) {
        final ejercicios = s['exercises'] as List<dynamic>? ?? [];
        return ejercicios.fold<double>(0, (sum, e) {
          final peso = (e['peso_usado'] is num) ? e['peso_usado'] : 0.0;
          final reps = (e['repsRealizadas'] is num) ? e['repsRealizadas'] : 0.0;
          final series = (e['series'] is num) ? e['series'] : 1.0;
          return sum + (peso * reps * series);
        });
      }).toList();
      return GraficoVolumen(etiquetas: List<String>.from(etiquetas), datos: List<double>.from(datos), titulo: 'Volumen total levantado');
    }
    // PRs (barras): máximo peso por ejercicio
    if (tipoGrafica == 4) {
      final Map<String, double> prs = {};
      for (var s in sesionesFiltradas) {
        final ejercicios = s['exercises'] as List<dynamic>? ?? [];
        for (var e in ejercicios) {
          final nombre = e['nombre'] ?? 'Ejercicio';
          final peso = (e['peso_usado'] is num) ? e['peso_usado'].toDouble() : 0.0;
          prs[nombre] = max(prs[nombre] ?? 0.0, peso);
        }
      }
      return GraficoPRs(ejercicios: prs.keys.toList(), pesos: prs.values.toList(), titulo: 'PRs por ejercicio');
    }
    // Default: progreso
    final etiquetas = sesionesFiltradas.map((s) => formatoFecha.format(s['date'] as DateTime)).toList();
    final datos = sesionesFiltradas.map((s) {
      final ejercicios = s['exercises'] as List<dynamic>? ?? [];
      return ejercicios.fold<double>(0, (sum, e) => sum + (e['repsRealizadas'] is num ? e['repsRealizadas'] : 0));
    }).toList();
    return GraficoLinea(etiquetas: List<String>.from(etiquetas), datos: List<double>.from(datos), titulo: 'Progreso de repeticiones');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamientos')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : sesiones.isEmpty
              ? const Center(child: Text('Aún no hay sesiones registradas.'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Semanal'),
                            selected: vistaResumen == 0,
                            onSelected: (v) {
                              vistaResumen = 0;
                              _actualizarResumen();
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Mensual'),
                            selected: vistaResumen == 1,
                            onSelected: (v) {
                              vistaResumen = 1;
                              _actualizarResumen();
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Global'),
                            selected: vistaResumen == 2,
                            onSelected: (v) {
                              vistaResumen = 2;
                              _actualizarResumen();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            vistaResumen == 0
                                ? 'Resumen semanal'
                                : vistaResumen == 1
                                    ? 'Resumen mensual'
                                    : 'Resumen global',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          _construirResumenDesdeAnalisis(),
                          const Divider(height: 32),
                            Row(
                            children: [
                              Expanded(
                              child: DropdownButton<int>(
                                value: tipoGrafica,
                                isExpanded: true,
                                dropdownColor: Colors.black87,
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text('Progreso', style: TextStyle(color: Colors.white)),
                                ),
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('Distribución', style: TextStyle(color: Colors.white)),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('Comparativa', style: TextStyle(color: Colors.white)),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text('Volumen', style: TextStyle(color: Colors.white)),
                                ),
                                DropdownMenuItem(
                                  value: 4,
                                  child: Text('PRs', style: TextStyle(color: Colors.white)),
                                ),
                                ],
                                onChanged: (v) {
                                setState(() => tipoGrafica = v ?? 0);
                                },
                              ),
                              ),
                            ],
                            ),
                          const SizedBox(height: 12),
                          _buildGraficaDinamica(),
 
              const Divider(height: 32),
              Text('Comentarios',
                style: Theme.of(context).textTheme.titleLarge),
              ...((resumen['comentarios'] ?? []) as List)
                .map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text('• $c'),
                  )),
              const Divider(height: 32),
              Text('Ejercicios incompletos',
                style: Theme.of(context).textTheme.titleLarge),
              ...((resumen['ejercicios_incompletos'] ?? []) as List)
                .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '${e['dia']}: ${e['nombre']} (${e['grupoMuscular']}) - Reps: ${e['repsRealizadas']}/${e['repsPlanificadas']}'),
                  )),
              const Divider(height: 32),
              Text('Sesiones de entrenamiento',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...sesionesFiltradas.map((sesion) {
                            try {
                              final fecha = (sesion['date'] as DateTime);
                              final ejercicios =
                                  sesion['exercises'] as List<dynamic>? ?? [];
                              final estado = ejercicios.every((e) =>
                                      e is Map &&
                                      e['completed'] != null &&
                                      e['completed'] == true)
                                  ? 'completo'
                                  : 'incompleto';

                              return ExpansionTile(
                                title: Text('Fecha: ${formatoFecha.format(fecha)}'),
                                subtitle: Text(
                                    'Ejercicios: ${ejercicios.length} - Estado: $estado'),
                                leading: Icon(
                                  estado == 'completo'
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: estado == 'completo'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                children: [
                                  const Divider(),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 4),
                                    child: Text('Ejercicios realizados:',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  ...ejercicios.map((e) {
                                    final nombre = e['nombre'] ?? 'Sin nombre';
                                    final repsPlanificadas = e['repsPlanificadas'] ?? '-';
                                    final repsRealizadas = e['repsRealizadas'] ?? '-';
                                    final completed = e['completed'] == true;
                                    final pesoPlanificado = (e['pesoPlanificado'] is num) ? e['pesoPlanificado'] : null;
                                    final pesoUsado = (e['peso_usado'] is num) ? e['peso_usado'] : null;

                                    String detalle = 'Reps planificadas: $repsPlanificadas - Reps realizadas: $repsRealizadas';
                                    if (pesoPlanificado != null) {
                                      if (pesoPlanificado > 0) {
                                        detalle += ' - Peso planificado: ${pesoPlanificado}kg';
                                      } else {
                                        detalle += ' - Sin peso';
                                      }
                                      if (pesoUsado != null) {
                                        if (pesoUsado > 0) {
                                          detalle += ' - Peso usado: ${pesoUsado}kg';
                                        } else {
                                          detalle += ' - Peso usado: Sin peso';
                                        }
                                      }
                                    }

                                    return ListTile(
                                      title: Text(nombre),
                                      subtitle: Text(detalle),
                                      trailing: Icon(
                                        completed ? Icons.check : Icons.close,
                                        color: completed ? Colors.green : Colors.red,
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                ],
                              );
                            } catch (_) {
                              return const SizedBox();
                            }
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _construirResumenDesdeAnalisis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Días entrenados: ${resumen['total_dias'] ?? 0}'),
        Text('Porcentaje cumplido: ${resumen['porcentaje_cumplimiento'] ?? 0}%'),
        Text('Días cumplidos: ${resumen['dias_cumplidos'] ?? 0}'),
        Text('Promedio de repeticiones por sesión: ${resumen['promedio_reps'] ?? 0}'),
        Text('Promedio de peso usado por ejercicio: ${resumen['promedio_peso'] ?? 0} kg'),
        Text('Ejercicio más frecuente: ${resumen['ejercicio_frecuente'] ?? "-"}'),
        Text('Racha máxima de días entrenados: ${resumen['racha_maxima'] ?? 0}'),
      ],
    );
  }

}
