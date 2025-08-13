import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoLinea extends StatelessWidget {
  final List<String> etiquetas;
  final List<double> datos;
  final String titulo;
  final bool animado;

  const GraficoLinea({
    super.key,
    required this.etiquetas,
    required this.datos,
    this.titulo = '',
    this.animado = true,
  });

  @override
  Widget build(BuildContext context) {
    final promedio = datos.isNotEmpty
        ? datos.reduce((a, b) => a + b) / datos.length
        : 0.0;

    final Color colorLinea = promedio >= 80
        ? Colors.greenAccent
        : (promedio >= 50 ? Colors.orangeAccent : Colors.redAccent);

    final Color areaColor = colorLinea.withOpacity(0.2);

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
          child: LineChart(
            LineChartData(
              minY: 0,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  getTooltipItems: (spots) => spots.map((spot) {
                    return LineTooltipItem(
                      '${etiquetas[spot.x.toInt()]}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '${spot.y.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < etiquetas.length) {
                        return Text(etiquetas[index],
                            style: const TextStyle(fontSize: 10));
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 32,
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
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    etiquetas.length,
                    (i) => FlSpot(i.toDouble(), datos[i]),
                  ),
                  isCurved: true,
                  color: colorLinea,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData:
                      BarAreaData(show: true, color: areaColor),
                ),
              ],
            ),
            duration:
                animado ? const Duration(milliseconds: 800) : Duration.zero,
          ),
        ),
      ],
    );
  }
}
