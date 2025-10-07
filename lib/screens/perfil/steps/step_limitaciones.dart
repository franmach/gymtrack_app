import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../perfil_wizard_controller.dart';

class StepLimitacionesScreen extends StatefulWidget {
  const StepLimitacionesScreen({super.key});

  @override
  State<StepLimitacionesScreen> createState() => _StepLimitacionesScreenState();
}

class _StepLimitacionesScreenState extends State<StepLimitacionesScreen> {
  final _form = GlobalKey<FormState>();
  final _textoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = context.read<PerfilWizardController>().data;
    _textoCtrl.text = d.textoLesiones ?? '';
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
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
            const Text('Limitaciones físicas / Lesiones (opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _textoCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                  labelText: 'Describe lesiones o limitaciones (opcional)'),
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
                    ctrl.setLimitaciones(texto: _textoCtrl.text);
                    ctrl.next();
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