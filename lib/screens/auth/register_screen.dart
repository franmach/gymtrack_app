import 'package:flutter/material.dart';
import 'package:gymtrack_app/services/auth_service.dart';
import 'package:gymtrack_app/models/usuario.dart';
import 'package:gymtrack_app/screens/dashboard/dashboard_screen.dart';

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
  bool obscureText = true;

  void _registrarUsuario() async {
    final esValido = _registerKey.currentState!.validate();
    if (!esValido) return;

    _registerKey.currentState!.save();

    try {
      final authService = AuthService();

      // Construir el modelo de usuario con los datos capturados
      final nuevoUsuario = Usuario(
        uid: '', // Se asignará en Firestore por el `uid` del Auth
        nombre: nombre,
        apellido: apellido,
        email: email,
        edad: edad,
        peso: peso,
        altura: altura,
        disponibilidad: disponibilidadSemanal,
        nivelExperiencia: nivelSeleccionado ?? '',
        objetivo: objetivoEntrenamiento,
        rol: 'Alumno', // Se le asigna alumno por defecto
        fechaRegistro: DateTime.now(),
      );

      // Llamar al servicio
      await authService.registrarUsuario(
        email: email,
        password: password,
        usuario: nuevoUsuario,
      );

      // Mostrar mensaje de éxito o redirigir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cuenta creada con éxito')),
      );

      // Redirigir a pantalla principal o login
      // 4) Esperamos un breve intervalo
      await Future.delayed(const Duration(seconds: 1));

      // 5) Navegamos al Dashboard reemplazando el LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👍 Registro exitoso'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

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
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')
                            .hasMatch(value)) {
                          return 'Solo se permiten letras';
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
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')
                            .hasMatch(value)) {
                          return 'Solo se permiten letras';
                        }
                        return null;
                      },
                      onSaved: (value) => apellido = value ??
                          '', // cuando valido todo, si estan los campos bien guarda
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      //Ingreso edad ---------------------------------------------------------------------------------------
                      decoration: InputDecoration(
                        labelText: 'Edad',
                        prefixIcon: Icon(Icons.timeline),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }

                        final numero = int.tryParse(value);
                        if (numero == null) {
                          return 'Debe ser un número entero';
                        }
                        if (numero <= 0) {
                          return 'Debe ser mayor a cero';
                        }
                        return null;
                      },
                      onSaved: (value) => edad = int.tryParse(value ?? '0') ??
                          0, // cuando valido todo, si estan los campos bien guarda
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
                      obscureText: obscureText,
                      //Ingreso contrasena ---------------------------------------------------------------------------------------
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            }),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese una contraseña';
                        }
                        if (value.length < 6) {
                          return 'Debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                      onSaved: (value) => password = value ??
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

                        final pesoNum = double.tryParse(value);
                        if (pesoNum == null) {
                          return 'Debe ser un número válido';
                        }

                        if (pesoNum < 30 || pesoNum > 300) {
                          return 'Ingrese un peso realista (30–300 kg)';
                        }
                        return null;
                      },
                      onSaved: (value) => peso = double.tryParse(
                              value ?? '0') ??
                          0.0, // cuando valido todo, si estan los campos bien guarda
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      //Ingreso altura ---------------------------------------------------------------------------------------
                      decoration: InputDecoration(
                        labelText: 'Altura',
                        prefixIcon: Icon(Icons.fitness_center),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }

                        final alturaNum = double.tryParse(value);
                        if (alturaNum == null) {
                          return 'Debe ser un número válido';
                        }

                        if (alturaNum < 0.5 || alturaNum > 2.5) {
                          return 'Ingrese una altura realista (0.5–2.5 m)';
                        }

                        return null;
                      },
                      onSaved: (value) => altura = double.tryParse(
                              value ?? '0') ??
                          0.0, // cuando valido todo, si estan los campos bien guarda
                    ),
                    SizedBox(height: 16),
                    //Ingreso nivel de experiencia---------------------------------------------------------------------------------------
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Nivel de experiencia',
                        prefixIcon: Icon(Icons.auto_graph_outlined),
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
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      //Ingreso edad ---------------------------------------------------------------------------------------
                      decoration: InputDecoration(
                        labelText: 'Disponibilidad semanal',
                        hintText: 'Entre 1 y 7 dias',
                        prefixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }

                        final numero = int.tryParse(value);
                        if (numero == null) {
                          return 'Debe ser un número';
                        }

                        if (numero < 1 || numero > 7) {
                          return 'Debe estar entre 1 y 7 días';
                        }

                        return null;
                      },
                      onSaved: (value) => disponibilidadSemanal = int.tryParse(
                              value ?? '0') ??
                          0, // cuando valido todo, si estan los campos bien guarda
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () {
                          _registrarUsuario();
                          print("click");
                        },
                        child: const Text("Guardar"))
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
