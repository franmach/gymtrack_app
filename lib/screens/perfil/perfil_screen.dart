import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'completar_perfil.dart';
import 'package:gymtrack_app/screens/rutina/mis_rutinas_screen.dart';

/// 🔧 Pantalla principal del perfil de usuario
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // 🔁 Modo edición activado o no
  bool modoEdicion = false;

  // 📝 Controladores para campos de texto
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController alturaController = TextEditingController();
  final TextEditingController disponibilidadController =
      TextEditingController();

  // 🎯 Lista de niveles de experiencia para el Dropdown
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

  // ✅ Clave del formulario para validaciones
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
                final bool incompleto = userData?['perfilCompleto'] == false;

                //  Obtener datos del usuario

                final nombre = userData?['nombre'] ?? '';
                final apellido = userData?['apellido'] ?? '';
                final email = user.email ?? '';
                final edad = userData?['edad']?.toString() ?? '';
                final peso = userData?['peso']?.toString() ?? '';
                final altura = userData?['altura']?.toString() ?? '';
                final disponibilidadSemanal =
                    userData?['disponibilidadSemanal']?.toString() ?? '';
                if (!modoEdicion && objetivoSeleccionado == null) {
                  objetivoSeleccionado = userData?['objetivo'] ?? '';
                }
                // Validar que el valor realmente esté en la lista
                if (!objetivos.contains(objetivoSeleccionado)) {
                  objetivoSeleccionado = null;
                }
                final nivel = userData?['nivelExperiencia'] ?? '';
                final imagenUrl = userData?['imagen_url'];

                //  Llenar campos si no se está editando
                if (!modoEdicion) {
                  nombreController.text = nombre;
                  apellidoController.text = apellido;
                  pesoController.text = peso;
                  alturaController.text = altura;
                  disponibilidadController.text = disponibilidadSemanal;
                  nivelSeleccionado = nivel;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 📸 Imagen de perfil
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: imagenUrl != null &&
                                    imagenUrl.isNotEmpty
                                ? NetworkImage(imagenUrl)
                                    as ImageProvider<Object>
                                : const AssetImage(
                                        'assets/images/profile_placeholder.png')
                                    as ImageProvider<Object>,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 🧑‍💼 Nombre y Apellido
                        modoEdicion
                            ? Column(
                                children: [
                                  CustomTextField(
                                    controller: nombreController,
                                    label: 'Nombre',
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Campo obligatorio';
                                      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')
                                          .hasMatch(value)) {
                                        return 'Solo se permiten letras';
                                      }
                                      return null;
                                    },
                                  ),
                                  CustomTextField(
                                    controller: apellidoController,
                                    label: 'Apellido',
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Campo obligatorio';
                                      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')
                                          .hasMatch(value)) {
                                        return 'Solo se permiten letras';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              )
                            : ProfileField(
                                label: 'Nombre y Apellido',
                                value: '$nombre $apellido',
                              ),

                        //  Email (no editable)
                        ProfileField(label: 'Email', value: email),

                        //  Edad (no editable)
                        ProfileField(label: 'Edad', value: edad),

                        //  Peso
                        modoEdicion
                            ? CustomTextField(
                                controller: pesoController,
                                label: 'Peso (kg)',
                                validator: (value) {
                                  final num = double.tryParse(value ?? '');
                                  if (value == null || value.isEmpty)
                                    return 'Campo obligatorio';
                                  if (num == null || num < 30 || num > 300)
                                    return 'Peso inválido (30–300 kg)';
                                  return null;
                                },
                              )
                            : ProfileField(
                                label: 'Peso (kg)', value: '$peso kg'),

                        //  Altura
                        modoEdicion
                            ? CustomTextField(
                                controller: alturaController,
                                label: 'Altura (cm)',
                                validator: (value) {
                                  final num = double.tryParse(value ?? '');
                                  if (value == null || value.isEmpty)
                                    return 'Campo obligatorio';
                                  if (num == null || num < 50 || num > 250)
                                    return 'Altura inválida (50–250 cm)';
                                  return null;
                                },
                              )
                            : ProfileField(
                                label: 'Altura (cm)', value: '$altura cm'),

                        // ⏱ Disponibilidad
                        modoEdicion
                            ? CustomTextField(
                                controller: disponibilidadController,
                                label: 'Días disponibles por semana (1-7)',
                                validator: (value) {
                                  final num = int.tryParse(value ?? '');
                                  if (value == null || value.isEmpty)
                                    return 'Campo obligatorio';
                                  if (num == null || num < 1 || num > 7)
                                    return 'Debe ser un número entre 1 y 7';
                                  return null;
                                },
                              )
                            : ProfileField(
                                label: 'Disponibilidad semanal',
                                value: '$disponibilidadSemanal dias por semana',
                              ),

                        //  Nivel de experiencia (Dropdown)
                        modoEdicion
                            ? DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Nivel de experiencia',
                                  border: OutlineInputBorder(),
                                ),
                                value: nivelSeleccionado,
                                items: nivelesExperiencia.map((String nivel) {
                                  return DropdownMenuItem(
                                    value: nivel,
                                    child: Text(nivel),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    nivelSeleccionado = value;
                                  });
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Seleccione su nivel de experiencia'
                                        : null,
                              )
                            : ProfileField(
                                label: 'Nivel de experiencia', value: nivel),

                        const SizedBox(height: 12),

                        //  Objetivo
                        modoEdicion
                            ? DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                    labelText: 'Objetivo',
                                    border: OutlineInputBorder()),
                                value: objetivoSeleccionado,
                                items: objetivos.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    objetivoSeleccionado = value!;
                                  });
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Campo obligatorio'
                                        : null,
                              )
                            : ProfileField(
                                label: 'Objetivo',
                                value: objetivoSeleccionado ?? ''),

                        const SizedBox(height: 12),

                        //  Botones
                        modoEdicion
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        // Guardar datos
                                        await FirebaseFirestore.instance
                                            .collection('usuarios')
                                            .doc(user.uid)
                                            .update({
                                          'nombre':
                                              nombreController.text.trim(),
                                          'apellido':
                                              apellidoController.text.trim(),
                                          'peso':
                                              double.parse(pesoController.text),
                                          'altura': double.parse(
                                              alturaController.text),
                                          'disponibilidadSemanal': int.parse(
                                              disponibilidadController.text),
                                          'objetivo':
                                              objetivoSeleccionado ?? '',
                                          'nivelExperiencia':
                                              nivelSeleccionado ?? '',
                                        });

                                        setState(() {
                                          modoEdicion = false;
                                        });

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Perfil actualizado')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.save),
                                    label: const Text('Guardar cambios'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        modoEdicion = false;
                                      });
                                    },
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Cancelar'),
                                  ),
                                ],
                              )
                            : ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    modoEdicion = true;
                                  });
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Editar Perfil'),
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
                                        CompletarPerfilScreen(uid: uid),
                                  ),
                                );
                              },
                              child: const Text('Completar perfil'),
                            ),
                          ),
                        // Si el perfil está completo, mostrar botón para ver rutina
                        if (!incompleto)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const MisRutinasScreen()),
                                );
                              },
                              child: const Text('Ver mis rutinas'),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

///  Widget reutilizable para mostrar campos no editables
class ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
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

/// Widget reutilizable para campos editables
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
