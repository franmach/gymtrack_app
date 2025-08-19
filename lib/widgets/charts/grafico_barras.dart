import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoBarras extends StatelessWidget {
  final List<String> etiquetas; // Ej: ['Semana 1', 'Semana 2']
  final List<double> datos;     // Ej: [300, 450]
  final String titulo;
  final bool animado;

  const GraficoBarras({
    super.key,
    required this.etiquetas,
    required this.datos,
    this.titulo = '',
    this.animado = true,
  });

  @override
  Widget build(BuildContext context) {
    final double maxY = datos.isNotEmpty ? (datos.reduce((a, b) => a > b ? a : b) * 1.2) : 0;

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
              barGroups: List.generate(etiquetas.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: datos[i],
                      color: datos[i] >= (maxY * 0.5)
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 == 0) {
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
                      if (index >= 0 && index < etiquetas.length) {
                        return Text(
                          etiquetas[index],
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 32,
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
