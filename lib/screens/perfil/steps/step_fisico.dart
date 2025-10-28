import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../perfil_wizard_controller.dart';

class StepFisicoScreen extends StatefulWidget {
  const StepFisicoScreen({super.key});

  @override
  State<StepFisicoScreen> createState() => _StepFisicoScreenState();
}

class _StepFisicoScreenState extends State<StepFisicoScreen> {
  final _form = GlobalKey<FormState>();
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  String? _genero;

  @override
  void initState() {
    super.initState();
    final d = context.read<PerfilWizardController>().data;
    if (d.peso != null) _pesoCtrl.text = d.peso!.toString();
    if (d.altura != null) _alturaCtrl.text = d.altura!.toString();
    _genero = d.genero;
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    super.dispose();
  }

  String? _valPeso(String? v) {
    final num = double.tryParse(v ?? '');
    if (num == null || num < 30 || num > 300) {
      return 'Peso entre 30 y 300 kg';
    }
    return null;
  }

  String? _valAltura(String? v) {
    final num = double.tryParse(v ?? '');
    if (num == null || num < 50 || num > 250) {
      return 'Altura inválida (50–250 cm)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PerfilWizardController>();
    return Form(
      key: _form,
      child: LayoutBuilder(
        builder: (context, _) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Datos físicos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pesoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  validator: _valPeso,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _alturaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Altura (cm)'),
                  validator: _valAltura,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _genero,
                  decoration: const InputDecoration(labelText: 'Género'),
                  items: const [
                    DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                    DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                  onChanged: (v) => setState(() => _genero = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => ctrl.back(),
                      child: const Text('Atrás'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (_form.currentState?.validate() ?? false) {
                          ctrl.setFisicos(
                            peso: double.parse(_pesoCtrl.text),
                            altura: double.parse(_alturaCtrl.text),
                            genero: _genero!,
                          );
                          ctrl.next();
                        }
                      },
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}