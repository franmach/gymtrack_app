import 'package:flutter/material.dart';
import 'package:gymtrack_app/services/auth_service.dart';
import 'package:gymtrack_app/models/usuario_basico.dart';
import 'package:gymtrack_app/screens/perfil/perfil_wizard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registerKey = GlobalKey<FormState>();
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

  // Helper local para SnackBars estilizados
  void _showSnack(String text,
      {required Color bg,
      IconData? icon,
      Duration duration = const Duration(seconds: 3)}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, color: Colors.black),
              if (icon != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: duration,
        ),
      );
  }

  void _registrarUsuario() async {
    final esValido = _registerKey.currentState!.validate();
    if (!esValido) return;

    _registerKey.currentState!.save();

    if (fechaNacimiento == null) {
      _showSnack(
        'Debes seleccionar tu fecha de nacimiento',
        bg: Colors.amberAccent,
        icon: Icons.info_outline,
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
          errorFechaNacimiento = 'Debes tener al menos 10 años para registrarte.';
        });
        _showSnack(
          errorFechaNacimiento!,
          bg: Colors.amberAccent,
          icon: Icons.warning_amber_rounded,
        );
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

      _showSnack('Registro exitoso', bg: Colors.lightGreenAccent, icon: Icons.check);

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PerfilWizardScreen(uid: uid)),
      );
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _showSnack(errorMsg, bg: Colors.redAccent, icon: Icons.error_outline);
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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - kToolbarHeight,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo encima del formulario
                    Image.asset('assets/images/logo.png', height: 96),
                    const SizedBox(height: 16),
                    Form(
                      key: _registerKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //Ingreso nombre ---------------------------------------------------------------------------------------
                          TextFormField(
                            decoration: InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder()),
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
                          const SizedBox(height: 16),
                          //Ingreso apellido---------------------------------------------------------------------------------------
                          TextFormField(
                            decoration: InputDecoration(
                                labelText: 'Apellido',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder()),
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
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: _seleccionarFechaNacimiento,
                              child: Text(fechaNacimiento == null
                                  ? 'Seleccionar fecha de nacimiento'
                                  : 'Fecha: ${fechaNacimiento!.toLocal().toString().split(' ')[0]}')),
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
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder()),
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
                          const SizedBox(height: 16),
                          TextFormField(
                            obscureText: obscureText,
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
                                border: OutlineInputBorder()),
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
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: () {
                                _registrarUsuario();
                              },
                              child: const Text("Guardar")),
                        ],
                      ),
                    ),
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
