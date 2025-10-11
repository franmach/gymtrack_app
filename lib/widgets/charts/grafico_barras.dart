import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../gymtrack_theme.dart';
import '../chart_helpers.dart';

class GraficoBarras extends StatelessWidget {
  final List<String> etiquetas; // Ej: ['2025-01-01', ...] o ['Semana 1', ...]
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
    // muestreo para evitar solapamiento de labels
    final sampledMax = 14;
    final sEtiquetas = sampleSeries(etiquetas, sampledMax);
    final sDatos = sampleSeries(datos, sampledMax);

    final double maxY = sDatos.isNotEmpty
        ? (sDatos.reduce((a, b) => a > b ? a : b) * 1.2)
        : 0;

    final many = sEtiquetas.length > 8;

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
                child: Text(titulo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: blanco)),
              ),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: maxY > 0 ? maxY : 1,
                  barGroups: List.generate(sEtiquetas.length, (i) {
                    final val = sDatos[i];
                    final color = val >= (maxY * 0.5) ? verdeFluor : Colors.orangeAccent;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          color: color,
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
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value % (maxY > 0 ? (maxY / 4).round() : 1) == 0) {
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
                          if (index >= 0 && index < sEtiquetas.length) {
                            final lbl = compactLabel(sEtiquetas[index], short: many);
                            final widget = Text(lbl, style: const TextStyle(fontSize: 10, color: blanco));
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
