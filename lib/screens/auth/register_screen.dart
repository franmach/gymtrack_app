import 'package:flutter/material.dart';
import 'package:gymtrack_app/services/auth_service.dart';
import 'package:gymtrack_app/models/usuario_basico.dart';
import 'package:gymtrack_app/screens/perfil/completar_perfil.dart';

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
  String password = '';
  int edad = 0;
  bool obscureText = true;
  DateTime? fechaNacimiento;
  String? errorFechaNacimiento;

  int _calcularEdad(DateTime fecha) {
    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    return edad;
  }

  void _registrarUsuario() async {
    final esValido = _registerKey.currentState!.validate();
    if (!esValido) return;

    _registerKey.currentState!.save();

    if (fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar tu fecha de nacimiento'),
        ),
      );
      return;
    }

    try {
      final authService = AuthService();
      final credenciales = await authService.registrarConEmail(
        email: email,
        password: password,
      );

      final uid = credenciales.user!.uid;
      final edadCalculada = _calcularEdad(fechaNacimiento!);

      if (edadCalculada < 10) {
        setState(() {
          errorFechaNacimiento =
              'Debes tener al menos 10 años para registrarte.';
        });
        return;
      } else {
        setState(() {
          errorFechaNacimiento = null;
        });
      }

      final usuarioBasico = UsuarioBasico(
        uid: uid,
        nombre: nombre,
        apellido: apellido,
        fechaNacimiento: fechaNacimiento,
        edad: edadCalculada,
        email: email,
        perfilCompleto: false,
        fechaRegistro: DateTime.now(),
      );

      await authService.guardarUsuarioBasico(usuarioBasico);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CompletarPerfilScreen(uid: uid)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _seleccionarFechaNacimiento() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        fechaNacimiento = picked;
      });
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
                    ElevatedButton(
                      onPressed: _seleccionarFechaNacimiento,
                      child: Text(fechaNacimiento == null
                          ? 'Seleccionar fecha de nacimiento'
                          : 'Fecha: ${fechaNacimiento!.toLocal().toString().split(' ')[0]}'),
                    ),
                    Visibility(
                      visible: errorFechaNacimiento != null,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorFechaNacimiento ?? '',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
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
