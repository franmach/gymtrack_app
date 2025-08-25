import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/models/progresoCorporal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class VisualizarProgresoScreen extends StatefulWidget {
  const VisualizarProgresoScreen({super.key});

  @override
  State<VisualizarProgresoScreen> createState() =>
      _VisualizarProgresoScreenState();
}

class _VisualizarProgresoScreenState extends State<VisualizarProgresoScreen> {
  List<ProgresoCorporal> registros = [];
  bool cargando = true;
  String filtroSeleccionado = '30';
  final Map<String, String> opcionesFiltro = {
    '30': 'Últimos 30 días',
    '90': 'Últimos 3 meses',
    'all': 'Todo el historial',
  };

  @override
  void initState() {
    super.initState();
    _cargarRegistros();
  }

  Future<void> _cargarRegistros() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('progreso_corporales')
        .doc(uid)
        .collection('registros')
        .orderBy('fecha', descending: false)
        .get();

    setState(() {
      registros =
          snapshot.docs.map((d) => ProgresoCorporal.fromMap(d.data())).toList();
      cargando = false;
    });
  }

  List<ProgresoCorporal> _filtrarRegistros() {
    if (filtroSeleccionado == 'all') return registros;
    final dias = int.tryParse(filtroSeleccionado) ?? 30;
    final desde = DateTime.now().subtract(Duration(days: dias));
    return registros.where((r) => r.fecha.isAfter(desde)).toList();
  }

  String _diferencia(double actual, double inicial) {
    final dif = (actual - inicial);
    return dif > 0 ? '+${dif.toStringAsFixed(1)}' : dif.toStringAsFixed(1);
  }

  Widget _graficoPeso(List<ProgresoCorporal> datos) {
    final spots = datos
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.peso))
        .toList();
    final inicial = datos.first.peso;
    final actual = datos.last.peso;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Peso (kg)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                )
              ],
            ))),
        const SizedBox(height: 8),
        Text(
            'Has cambiado ${_diferencia(actual, inicial)} kg desde el primer registro.')
      ],
    );
  }

  Widget _graficoMedidas(List<ProgresoCorporal> datos) {
    final medidas = ['cintura', 'brazos', 'piernas', 'pecho'];
    final colores = [Colors.orange, Colors.blue, Colors.purple, Colors.red];

    List<LineChartBarData> lineas = [];
    for (int i = 0; i < medidas.length; i++) {
      final spots = datos
          .asMap()
          .entries
          .map((e) => FlSpot(
              e.key.toDouble(),
              switch (medidas[i]) {
                'cintura' => e.value.cintura,
                'brazos' => e.value.brazos,
                'piernas' => e.value.piernas,
                'pecho' => e.value.pecho,
                _ => 0
              }))
          .toList();
      lineas.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: colores[i],
        barWidth: 2,
        dotData: FlDotData(show: false),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Medidas corporales (cm)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 200,
          child: LineChart(LineChartData(
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: lineas,
          )),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: List.generate(
              medidas.length,
              (i) => Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 12, height: 12, color: colores[i]),
                    const SizedBox(width: 4),
                    Text(medidas[i].capitalize()),
                  ])),
        ),
      ],
    );
  }

  Widget _listadoRegistros(List<ProgresoCorporal> datos) {
    final format = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Historial de registros',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...datos.reversed.map((r) => Card(
              child: ListTile(
                title: Text('Fecha: ${format.format(r.fecha)}'),
                subtitle: Text(
                    'Peso: ${r.peso} kg | Cintura: ${r.cintura} cm | Brazos: ${r.brazos} cm | Piernas: ${r.piernas} cm | Pecho: ${r.pecho} cm'),
              ),
            ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final datosFiltrados = _filtrarRegistros();
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizar Progreso Corporal')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    value: filtroSeleccionado,
                    decoration:
                        const InputDecoration(labelText: 'Filtrar por fecha'),
                    items: opcionesFiltro.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (valor) {
                      if (valor == null) return;
                      setState(() => filtroSeleccionado = valor);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (datosFiltrados.length >= 2) ...[
                    _graficoPeso(datosFiltrados),
                    const SizedBox(height: 28),
                    _graficoMedidas(datosFiltrados),
                    const SizedBox(height: 28),
                  ] else
                    const Text(
                        'No hay suficientes datos para generar gráficos.'),
                  _listadoRegistros(datosFiltrados),
                ],
              ),
            ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
