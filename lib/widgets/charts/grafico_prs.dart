import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../gymtrack_theme.dart';
import '../chart_helpers.dart';

class GraficoPRs extends StatelessWidget {
  final List<String> ejercicios; // Ej: ['Sentadilla', ...]
  final List<double> pesos;      // Ej: [120, ...]
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
    // sample a tope 30 registros para mantener legibilidad
    final sEj = sampleSeries(ejercicios, 30);
    final sPesos = sampleSeries(pesos, 30);

    final double maxY = sPesos.isNotEmpty ? (sPesos.reduce((a, b) => a > b ? a : b) * 1.2) : 0;
    final many = sEj.length > 6;

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
              child: BarChart(
                BarChartData(
                  maxY: maxY > 0 ? maxY : 1,
                  barGroups: List.generate(sEj.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: sPesos[i],
                          color: verdeFluor,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value % (maxY > 0 ? (maxY / 4).round() : 10) == 0) {
                            return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: blanco));
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
                          if (index >= 0 && index < sEj.length) {
                            final txt = compactLabel(sEj[index], short: many);
                            final widget = Text(txt, style: const TextStyle(fontSize: 10, color: blanco), textAlign: TextAlign.center);
                            return Transform.rotate(angle: many ? -0.6 : 0, child: widget);
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: grisClaro.withOpacity(0.12))),
                  borderData: FlBorderData(show: false),
                ),
                swapAnimationDuration: animado ? const Duration(milliseconds: 600) : Duration.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
