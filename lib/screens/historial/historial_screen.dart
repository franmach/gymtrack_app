// 📄 GIMNASIO_SCREEN.DART – Corregido por Ángel y ChatGPT
// Incluye:
// - Mejora visual en el gráfico de historial (fl_chart)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Map<String, dynamic>> sesiones = [];
  bool cargando = true;
  final formatoFecha = DateFormat('dd/MM/yyyy');

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
          .where('userId', isEqualTo: uid)
          .orderBy('date', descending: true)
          .get();

      sesiones = snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data['date'] == null || data['exercises'] == null) return null;
            return data;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDayOfYear);
    return ((diff.inDays + firstDayOfYear.weekday) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamientos')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : sesiones.isEmpty
              ? const Center(child: Text('Aún no hay sesiones registradas.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Resumen semanal',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _construirResumenCompleto(),
                    const Divider(height: 32),
                    Text('Progreso por ejercicio (últimos 30 días)',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _construirGrafico(),
                    const Divider(height: 32),
                    Text('Sesiones de entrenamiento',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ...sesiones.map((sesion) {
                      try {
                        final fecha = (sesion['date'] as Timestamp).toDate();
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
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ...ejercicios.map((e) {
                              final nombre = e['nombre'] ?? 'Sin nombre';
                              final repsPlanificadas =
                                  e['repsPlanificadas'] ?? '-';
                              final repsRealizadas = e['repsRealizadas'] ?? '-';
                              final completed = e['completed'] == true;
                              return ListTile(
                                title: Text(nombre),
                                subtitle: Text(
                                    'Reps planificadas: $repsPlanificadas - Reps realizadas: $repsRealizadas'),
                                trailing: Icon(
                                    completed ? Icons.check : Icons.close,
                                    color:
                                        completed ? Colors.green : Colors.red),
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
    );
  }

  Widget _construirResumenCompleto() {
    final ahora = DateTime.now();
    final unaSemanaAtras = ahora.subtract(const Duration(days: 7));

    final sesionesSemana = sesiones.where((s) {
      final fecha = (s['date'] as Timestamp).toDate();
      return fecha.isAfter(unaSemanaAtras) && fecha.isBefore(ahora);
    }).toList();

    final diasEntrenados = sesionesSemana
        .map((s) => formatoFecha.format((s['date'] as Timestamp).toDate()))
        .toSet()
        .length;

    final completas = sesionesSemana.where((s) {
      final ejercicios = s['exercises'] as List<dynamic>? ?? [];
      return ejercicios.every((e) => e['completed'] == true);
    }).length;

    final porcentaje = sesionesSemana.isNotEmpty
        ? (completas / sesionesSemana.length * 100).round()
        : 0;

    final totalSesiones = sesiones.length;

    final fechasOrdenadas = sesiones
        .map((s) => DateUtils.dateOnly((s['date'] as Timestamp).toDate()))
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
        rachaMaxima = max(rachaMaxima, rachaActual);
      } else {
        rachaActual = 1;
      }
    }

    Map<int, int> sesionesPorSemana = {};
    for (var s in sesiones) {
      final fecha = (s['date'] as Timestamp).toDate();
      int week = getWeekNumber(fecha);
      sesionesPorSemana[week] = (sesionesPorSemana[week] ?? 0) + 1;
    }

    final mejorSemana = sesionesPorSemana.values.isNotEmpty
        ? sesionesPorSemana.values.reduce((a, b) => a > b ? a : b)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Días entrenados: $diasEntrenados'),
        Text('Porcentaje cumplido: $porcentaje%'),
        Text('Total de sesiones: $totalSesiones'),
        Text('Racha más larga: $rachaMaxima días'),
        Text('Mejor semana: $mejorSemana sesiones'),
      ],
    );
  }

  Widget _construirGrafico() {
    Map<String, int> repsPorEjercicio = {};
    final ahora = DateTime.now();
    final desde = ahora.subtract(const Duration(days: 30));

    final sesionesRango = sesiones.where((s) {
      final fecha = (s['date'] as Timestamp).toDate();
      return fecha.isAfter(desde) && fecha.isBefore(ahora);
    });

    for (var sesion in sesionesRango) {
      final ejercicios = sesion['exercises'] as List<dynamic>? ?? [];
      for (var e in ejercicios) {
        final nombre = e['nombre'] ?? 'Otro';
        final rawReps = e['repsRealizadas'];
        final reps = int.tryParse(rawReps.toString()) ?? 0;
        if (reps > 0) {
          repsPorEjercicio[nombre] = (repsPorEjercicio[nombre] ?? 0) + reps;
        }
      }
    }

    if (repsPorEjercicio.isEmpty) {
      return const Center(
        child: Text('No hay repeticiones registradas en los últimos 30 días.'),
      );
    }

    final etiquetas = repsPorEjercicio.keys.toList();
    final datos = repsPorEjercicio.values.toList();

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < etiquetas.length) {
                    return Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        etiquetas[index],
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 48,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0) {
                    return Text(value.toInt().toString(),
                        style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(etiquetas.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: datos[i].toDouble(),
                  width: 14,
                  color: Colors.tealAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              showingTooltipIndicators: [0],
            );
          }),
        ),
      ),
    );
  }
}
