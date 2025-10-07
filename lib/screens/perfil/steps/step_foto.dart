import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../perfil_wizard_controller.dart';

class StepFotoScreen extends StatelessWidget {
  const StepFotoScreen({super.key});

   @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PerfilWizardController>();
    final file = ctrl.data.imagenFile;
    final bytes = ctrl.data.imagenBytes;
    final networkUrl = ctrl.data.imagenUrl;

    // Determinar el ImageProvider según plataforma / origen
    ImageProvider? provider;
    if (kIsWeb && bytes != null) {
      provider = MemoryImage(bytes);
    } else if (!kIsWeb && file != null) {
      provider = FileImage(file);
    } else if (networkUrl != null) {
      provider = NetworkImage(networkUrl);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            const Text(
              'Foto de perfil (opcional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 70,
              backgroundImage: provider,
              child: provider == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Galería'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    await ctrl.setImagenXFile(picked);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Quitar'),
                  onPressed: () => ctrl.setImagenXFile(null),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () => ctrl.next(),
                child: const Text('Siguiente'),
              ),
            ),
        ],
      ),
    );
  }
}