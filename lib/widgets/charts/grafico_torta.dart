import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoTorta extends StatelessWidget {
  final Map<String, double> data; // Ej: {'Piernas': 30, 'Pecho': 25, ...}
  final String titulo;
  final bool animado;

  const GraficoTorta({
    super.key,
    required this.data,
    this.titulo = '',
    this.animado = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> colores = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
    ];

    final total = data.values.fold(0.0, (sum, value) => sum + value);

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
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              borderData: FlBorderData(show: false),
              sections: List.generate(data.length, (i) {
                final entry = data.entries.elementAt(i);
                final porcentaje = (entry.value / total) * 100;
                return PieChartSectionData(
                  color: colores[i % colores.length],
                  value: entry.value,
                  title: '${porcentaje.toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
            swapAnimationDuration:
                animado ? const Duration(milliseconds: 800) : Duration.zero,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: List.generate(data.length, (i) {
            final entry = data.entries.elementAt(i);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: colores[i % colores.length],
                ),
                const SizedBox(width: 4),
                Text(entry.key, style: const TextStyle(fontSize: 12)),
              ],
            );
          }),
        ),
      ],
    );
  }
}
