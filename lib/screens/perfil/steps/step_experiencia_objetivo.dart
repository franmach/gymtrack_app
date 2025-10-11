import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../perfil_wizard_controller.dart';

class StepExperienciaObjetivoScreen extends StatefulWidget {
  const StepExperienciaObjetivoScreen({super.key});

  @override
  State<StepExperienciaObjetivoScreen> createState() =>
      _StepExperienciaObjetivoScreenState();
}

class _StepExperienciaObjetivoScreenState
    extends State<StepExperienciaObjetivoScreen> {
  final _form = GlobalKey<FormState>();
  String? _nivel;
  String? _objetivo;

  final niveles = const [
    'Principiante (0–1 año)',
    'Intermedio (1–3 años)',
    'Avanzado (3+ años)',
  ];
  final objetivos = const [
    'Bajar de peso',
    'Ganar músculo',
    'Tonificar',
    'Mejorar resistencia',
  ];

  @override
  void initState() {
    super.initState();
    final d = context.read<PerfilWizardController>().data;
    _nivel = d.nivelExperiencia;
    _objetivo = d.objetivo;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PerfilWizardController>();
    return Form(
      key: _form,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Experiencia & Objetivo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _nivel,
              decoration:
                  const InputDecoration(labelText: 'Nivel de experiencia'),
              items: niveles
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              validator: (v) => v == null ? 'Campo obligatorio' : null,
              onChanged: (v) => setState(() => _nivel = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _objetivo,
              decoration: const InputDecoration(labelText: 'Objetivo físico'),
              items: objetivos
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              validator: (v) => v == null ? 'Campo obligatorio' : null,
              onChanged: (v) => setState(() => _objetivo = v),
            ),
            const Spacer(),
            Row(
              children: [
                OutlinedButton(
                    onPressed: () => ctrl.back(),
                    child: const Text('Atrás')),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_form.currentState?.validate() ?? false) {
                      ctrl.setExperienciaObjetivo(
                        nivel: _nivel!,
                        objetivo: _objetivo!,
                      );
                      ctrl.next();
                    }
                  },
                  child: const Text('Siguiente'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}