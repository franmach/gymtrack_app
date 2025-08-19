import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoPRs extends StatelessWidget {
  final List<String> ejercicios; // Ej: ['Sentadilla', 'Press banca', 'Peso muerto']
  final List<double> pesos;      // Ej: [120, 85, 150]
  final String titulo;
  final bool animado;

  const GraficoPRs({
    super.key,
    required this.ejercicios,
    required this.pesos,
    this.titulo = '',
    this.animado = true,
  });

  @override
  Widget build(BuildContext context) {
    final double maxY = pesos.isNotEmpty
        ? (pesos.reduce((a, b) => a > b ? a : b) * 1.2)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titulo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: List.generate(ejercicios.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: pesos[i],
                      color: Colors.deepPurpleAccent,
                      width: 20,
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurpleAccent,
                          Colors.purpleAccent.withOpacity(0.7),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value % 10 == 0) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < ejercicios.length) {
                        return Text(
                          ejercicios[index],
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 40,
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
            swapAnimationDuration:
                animado ? const Duration(milliseconds: 800) : Duration.zero,
          ),
        ),
      ],
    );
  }
}
