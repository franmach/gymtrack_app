import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/screens/dashboard/dashboard_screen.dart'; // Ajusta el paquete según tu pubspec.yaml

/// Pantalla de Login con Firebase Auth y navegación al Dashboard
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Key para identificar y validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para leer el texto ingresado
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  // Estado de carga y mensaje de error
  bool _loading = false;
  String? _errorMessage;

  /// Se dispara al presionar "Entrar"
  Future<void> _submit() async {
    // 1) Validamos el formulario
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 2) Intentamos autenticar con Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;

      // 3) Mostramos un SnackBar de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👍 Login exitoso'),
          duration: Duration(seconds: 2), // Duración configurable
        ),
      );

      // 4) Breve espera para que el usuario vea el mensaje
      await Future.delayed(const Duration(seconds: 2));

      // 5) Navegamos al Dashboard reemplazando el LoginScreen
      print('🔜 Navegando al Dashboard');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // 6) Manejamos errores de autenticación específicos
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          _errorMessage = 'Contraseña incorrecta';
          break;
        default:
          _errorMessage = 'Error: ${e.message}';
      }
    } catch (e) {
      // 7) Otros errores
      _errorMessage = 'Error inesperado: $e';
    } finally {
      // 8) Desactivamos el indicador de carga
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu email';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo Contraseña
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Mensaje de error
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 8),
              // Botón Entrar
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
