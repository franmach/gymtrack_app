import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../gymtrack_theme.dart';
import '../chart_helpers.dart';

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
    // sample
    final maxPoints = 18;
    final sEtiquetas = sampleSeries(etiquetas, maxPoints);
    final sDatos = sampleSeries(datos, maxPoints);

    final promedio = sDatos.isNotEmpty ? sDatos.reduce((a, b) => a + b) / sDatos.length : 0.0;
    final Color colorLinea = promedio >= 80 ? verdeFluor : (promedio >= 50 ? Colors.orangeAccent : Colors.redAccent);
    final Color areaColor = colorLinea.withOpacity(0.18);

    final many = sEtiquetas.length > 10;

    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titulo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: blanco)),
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
                          '${sEtiquetas[spot.x.toInt()]}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: '${spot.y.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white70)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: grisClaro.withOpacity(0.12))),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sEtiquetas.length) {
                            final txt = compactLabel(sEtiquetas[index], short: many);
                            final widget = Text(txt, style: const TextStyle(fontSize: 10, color: blanco));
                            return Transform.rotate(angle: many ? -0.6 : 0, child: widget);
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 36,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0) {
                            return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: blanco));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(sEtiquetas.length, (i) => FlSpot(i.toDouble(), sDatos[i])),
                      isCurved: true,
                      color: colorLinea,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: areaColor),
                    ),
                  ],
                ),
                duration: animado ? const Duration(milliseconds: 600) : Duration.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
