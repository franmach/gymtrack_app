import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/screens/rutina/mis_rutinas_screen.dart';
import 'completar_perfil.dart';
import 'package:gymtrack_app/screens/perfil/achievements_screen.dart';
import 'package:gymtrack_app/services/gamification_repository.dart';
import 'package:gymtrack_app/services/gamification_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  bool modoEdicion = false;

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController alturaController = TextEditingController();
  final TextEditingController disponibilidadController =
      TextEditingController();

  final List<String> nivelesExperiencia = [
    'Principiante (0–1 año)',
    'Intermedio (1–3 años)',
    'Avanzado (3+ años)',
  ];

  final List<String> objetivos = [
    'Bajar de peso',
    'Ganar músculo',
    'Tonificar',
    'Mejorar resistencia',
  ];

  String? nivelSeleccionado;
  String? objetivoSeleccionado;

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

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
                  .doc(uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final bool incompleto = userData?['perfilCompleto'] == false;

                final nombre = userData?['nombre'] ?? '';
                final apellido = userData?['apellido'] ?? '';
                final email = user.email ?? '';
                final edad = userData?['edad']?.toString() ?? '';
                final peso = userData?['peso']?.toString() ?? '';
                final altura = userData?['altura']?.toString() ?? '';
                final disponibilidadSemanal =
                    userData?['disponibilidadSemanal']?.toString() ?? '';
                final nivel = userData?['nivelExperiencia'] ?? '';
                final imagenUrl = userData?['imagen_url'];

                if (!modoEdicion) {
                  nombreController.text = nombre;
                  apellidoController.text = apellido;
                  pesoController.text = peso;
                  alturaController.text = altura;
                  disponibilidadController.text = disponibilidadSemanal;
                  if (userData != null &&
                      objetivos.contains(userData['objetivo'])) {
                    objetivoSeleccionado = userData['objetivo'];
                  } else {
                    objetivoSeleccionado = null;
                  }
                  nivelSeleccionado = nivel;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: imagenUrl != null &&
                                    imagenUrl.isNotEmpty
                                ? NetworkImage(imagenUrl)
                                : const AssetImage(
                                        'assets/images/profile_placeholder.png')
                                    as ImageProvider,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (modoEdicion) ...[
                          TextFormField(
                              controller: nombreController,
                              decoration:
                                  const InputDecoration(labelText: 'Nombre')),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: apellidoController,
                              decoration:
                                  const InputDecoration(labelText: 'Apellido')),
                        ] else ...[
                          Text('Nombre y Apellido',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text('$nombre $apellido'),
                        ],
                        const SizedBox(height: 16),
                        Text('Email',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(email),
                        const SizedBox(height: 16),
                        Text('Edad',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(edad),
                        const SizedBox(height: 16),
                        if (modoEdicion)
                          TextFormField(
                              controller: pesoController,
                              decoration:
                                  const InputDecoration(labelText: 'Peso (kg)'))
                        else ...[
                          Text('Peso (kg)',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text('$peso kg'),
                        ],
                        const SizedBox(height: 16),
                        if (modoEdicion)
                          TextFormField(
                              controller: alturaController,
                              decoration: const InputDecoration(
                                  labelText: 'Altura (cm)'))
                        else ...[
                          Text('Altura (cm)',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text('$altura cm'),
                        ],
                        const SizedBox(height: 16),
                        if (modoEdicion)
                          TextFormField(
                              controller: disponibilidadController,
                              decoration: const InputDecoration(
                                  labelText:
                                      'Días disponibles por semana (1–7)'))
                        else ...[
                          Text('Disponibilidad semanal',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text('$disponibilidadSemanal días por semana'),
                        ],
                        const SizedBox(height: 16),
                        if (modoEdicion)
                          DropdownButtonFormField<String>(
                            value: nivelSeleccionado,
                            items: nivelesExperiencia
                                .map((nivel) => DropdownMenuItem(
                                    value: nivel, child: Text(nivel)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => nivelSeleccionado = val),
                            decoration: const InputDecoration(
                                labelText: 'Nivel de experiencia'),
                          )
                        else ...[
                          Text('Nivel de experiencia',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text(nivel),
                        ],
                        const SizedBox(height: 16),
                        if (modoEdicion)
                          DropdownButtonFormField<String>(
                            value: objetivoSeleccionado,
                            items: objetivos
                                .map((obj) => DropdownMenuItem(
                                    value: obj, child: Text(obj)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => objetivoSeleccionado = val),
                            decoration:
                                const InputDecoration(labelText: 'Objetivo'),
                          )
                        else ...[
                          Text('Objetivo',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text(objetivoSeleccionado ?? ''),
                        ],
                        const SizedBox(height: 24),
                        Center(
                          child: modoEdicion
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _guardarCambios,
                                      icon: const Icon(Icons.save),
                                      label: const Text('Guardar cambios'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          setState(() => modoEdicion = false),
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Cancelar'),
                                    ),
                                  ],
                                )
                              : ElevatedButton.icon(
                                  onPressed: () =>
                                      setState(() => modoEdicion = true),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar Perfil'),
                                ),
                        ),
                        if (incompleto)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            CompletarPerfilScreen(uid: uid!)));
                              },
                              child: const Text('Completar perfil'),
                            ),
                          ),
                        if (!incompleto)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const MisRutinasScreen()));
                              },
                              child: const Text('Ver mis rutinas'),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.emoji_events),
                            label: const Text('Ver logros'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AchievementsScreen(
                                    uid: uid!,
                                    repo: GamificationRepository(
                                        FirebaseFirestore.instance,
                                        FirebaseAuth.instance),
                                    service: GamificationService(
                                      GamificationRepository(
                                          FirebaseFirestore.instance,
                                          FirebaseAuth.instance),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'nombre': nombreController.text.trim(),
        'apellido': apellidoController.text.trim(),
        'peso': double.tryParse(pesoController.text) ?? 0,
        'altura': double.tryParse(alturaController.text) ?? 0,
        'disponibilidadSemanal':
            int.tryParse(disponibilidadController.text) ?? 0,
        'objetivo': objetivoSeleccionado ?? '',
        'nivelExperiencia': nivelSeleccionado ?? '',
      });

      setState(() => modoEdicion = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    }
  }
}
