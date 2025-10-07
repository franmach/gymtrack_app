import 'package:flutter/material.dart';
import 'package:gymtrack_app/screens/main_tabbed_screen.dart';
import 'package:provider/provider.dart';
import '../perfil_wizard_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepResumenScreen extends StatelessWidget {
  const StepResumenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PerfilWizardController>();
    final d = ctrl.data;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _line('Peso', '${d.peso ?? '-'} kg'),
          _line('Altura', '${d.altura ?? '-'} cm'),
          _line('Género', d.genero ?? '-'),
          _line('Nivel', d.nivelExperiencia ?? '-'),
          _line('Objetivo', d.objetivo ?? '-'),
          _line('Disponibilidad', '${d.disponibilidad ?? '-'} días/sem'),
          _line('Duración', '${d.minPorSesion ?? '-'} min'),
          _line('Lesiones/Limitaciones',
              (d.textoLesiones?.isNotEmpty ?? false) ? 'Sí' : 'No'),
          const Spacer(),
          if (ctrl.saving)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => ctrl.back(),
                  child: const Text('Atrás'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar y generar rutina'),
                  onPressed: () async {
                    try {
                      await ctrl.confirmarGuardar();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Perfil guardado y rutina generada'),
                          ),
                        );
                        // Volver al contenedor con tabs (mantiene el menú inferior)
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MainTabbedScreen(),
                          ),
                          (r) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                flex: 2,
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(flex: 3, child: Text(value)),
          ],
        ),
      );
}
