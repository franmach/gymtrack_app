import 'package:flutter/material.dart';
//import 'package:gymtrack_app/services/auth_service.dart'; AUN NO CREADO

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registerKey = GlobalKey<FormState>();
  // Acá van: GlobalKey<FormState>, controladores, variables, etc.
  String email = '';
  String nombre = '';
  String apellido = '';
  int edad = 0;
  double peso = 0;
  double altura = 0;
  final List<String> nivelesExperiencia = [
    'Principiante (0–1 año)',
    'Intermedio (1–3 años)',
    'Avanzado (3+ años)',
  ];
  String? nivelSeleccionado;
  String objetivoEntrenamiento = '';
  int disponibilidadSemanal = 0;
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _registerKey,
                child: Column(
                  children: [
                    TextFormField(
                      //Ingreso nombre ---------------------------------------------------------------------------------------
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        return null;
                      },
                      onSaved: (value) => nombre = value ??
                          '', // cuando valido todo, si estan los campos bien guarda
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      //Ingreso apellido---------------------------------------------------------------------------------------
                      decoration: InputDecoration(
                        labelText: 'Apellido',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        return null;
                      },
                      onSaved: (value) => apellido = value ??
                          '', // cuando valido todo, si estan los campos bien guarda
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      //Ingreso email---------------------------------------------------------------------------------------
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        if (!value.contains('@')) {
                          return 'Debe contener un @';
                        }
                        return null;
                      },
                      onSaved: (value) => email = value ??
                          '', // cuando valido todo, si estan los campos bien guarda
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      //Ingreso peso ---------------------------------------------------------------------------------------
                      decoration: InputDecoration(
                        labelText: 'Peso',
                        prefixIcon: Icon(Icons.fitness_center),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }

                        final numero = double.tryParse(value);
                        if (numero == null) {
                          return 'Debe ser un número decimal';
                        }

                        if (numero <= 0) {
                          return 'Debe ser mayor a cero';
                        }

                        return null;
                      },
                      onSaved: (value) => peso = double.tryParse(
                              value ?? '0') ??
                          0.0, // cuando valido todo, si estan los campos bien guarda
                    ),
                    SizedBox(height: 16),

                    //Ingreso nivel de experiencia---------------------------------------------------------------------------------------
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                          labelText: 'Nivel de experiencia',
                          prefixIcon: Icon(Icons.auto_graph_outlined),
                          border: OutlineInputBorder(),),
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
                      validator: (value) => value == null
                          ? 'Seleccione su nivel de experiencia'
                          : null,
                      onSaved: (value) => nivelSeleccionado = value,
                    ),
                    SizedBox(height: 16),

                    //Ingreso objetivo---------------------------------------------------------------------------------------
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Objetivo',
                        hintText: 'Ej: Ganar músculo, bajar de peso...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      onSaved: (value) => objetivoEntrenamiento = value ?? '',
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese su objetivo'
                          : null,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
