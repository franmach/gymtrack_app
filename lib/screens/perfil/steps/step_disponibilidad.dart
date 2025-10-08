import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../perfil_wizard_controller.dart';

class StepDisponibilidadDuracionScreen extends StatefulWidget {
  const StepDisponibilidadDuracionScreen({super.key});

  @override
  State<StepDisponibilidadDuracionScreen> createState() =>
      _StepDisponibilidadDuracionScreenState();
}

class _StepDisponibilidadDuracionScreenState
    extends State<StepDisponibilidadDuracionScreen> {
  final _form = GlobalKey<FormState>();
  final _dispCtrl = TextEditingController();
  final _durCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = context.read<PerfilWizardController>().data;
    if (d.disponibilidad != null) {
      _dispCtrl.text = d.disponibilidad.toString();
    }
    if (d.minPorSesion != null) {
      _durCtrl.text = d.minPorSesion.toString();
    }
  }

  @override
  void dispose() {
    _dispCtrl.dispose();
    _durCtrl.dispose();
    super.dispose();
  }

  String? _valDisp(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 1 || n > 7) return 'Entre 1 y 7 días';
    return null;
  }

  String? _valDur(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 45 || n > 180) return 'Entre 45 y 180 minutos';
    return null;
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
            const Text('Disponibilidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dispCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Disponibilidad semanal (1-7 días)'),
              validator: _valDisp,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Duración por sesión (minutos)'),
              validator: _valDur,
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
                      ctrl.setDisponibilidad(
                        disponibilidad: int.parse(_dispCtrl.text),
                        minPorSesion: int.parse(_durCtrl.text),
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