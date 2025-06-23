import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el usuario autenticado
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('No hay usuario autenticado.'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;

                // Extraer datos o dejar campos vacíos
                final nombre = userData?['nombre'] ?? '';
                final apellido = userData?['apellido'] ?? '';
                final email = user.email ?? '';
                final peso = userData?['peso']?.toString() ?? '';
                final nivel = userData?['nivel_experiencia'] ?? '';
                final objetivo = userData?['objetivo'] ?? '';
                final imagenUrl = userData?['imagen_url'];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Imagen de perfil (por ahora fija o con Network si existe)
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: imagenUrl != null
                              ? NetworkImage(imagenUrl)
                              : const AssetImage(
                                      'assets/images/profile_placeholder.png')
                                  as ImageProvider,
                        ),
                      ),

                      const SizedBox(height: 20),

                      ProfileField(
                        label: 'Nombre y Apellido',
                        value: '$nombre $apellido',
                      ),
                      ProfileField(
                        label: 'Email',
                        value: email,
                      ),
                      ProfileField(
                        label: 'Peso',
                        value: '$peso kg',
                      ),
                      ProfileField(
                        label: 'Nivel de experiencia',
                        value: nivel,
                      ),
                      ProfileField(
                        label: 'Objetivo',
                        value: objetivo,
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: () {
                          // Más adelante lo conectaremos a la edición
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar Perfil'),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// Widget reutilizable para mostrar un campo del perfil
class ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileField({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value),
        ),
      ],
    );
  }
}
