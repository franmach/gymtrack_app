import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// LoginScreen es un StatefulWidget porque cambia de estado
/// (por ejemplo, cuando mostramos el indicador de carga o un error).
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Esta clase maneja el estado mutable de LoginScreen
class _LoginScreenState extends State<LoginScreen> {
  // Key para identificar y validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para leer el texto ingresado en los TextFormField
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl  = TextEditingController();

  // Variables de estado para indicar si estamos cargando o hay un error
  bool _loading = false;
  String? _errorMessage;

  /// Este método se dispara al presionar el botón "Entrar"
  Future<void> _submit() async {
    // 1) Validamos que todos los campos del Form sean válidos
    if (!_formKey.currentState!.validate()) return;

    // 2) Entramos en estado de "cargando"
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 3) Intentamos autenticar con FirebaseAuth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // 4) Si tiene éxito, navegamos al dashboard y reemplazamos esta pantalla
      if (!mounted) return;                      // Seguridad: ¿el widget sigue en el árbol?
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      // 5) Manejamos errores específicos de autenticación
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
      // 6) Cualquier otro tipo de error (red, etc.)
      _errorMessage = 'Error de red o inesperado';
    } finally {
      // 7) Siempre desactivamos el indicador de carga al finalizar
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    // Liberamos los controladores para evitar fugas de memoria
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold: estructura básica con AppBar y body
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // Espaciado interno
        child: Form(
          key: _formKey,                    // Asociamos el Form al _formKey
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === Campo de Email ===
              TextFormField(
                controller: _emailCtrl,                // Vincula el controlador
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',                  // Etiqueta
                  prefixIcon: Icon(Icons.email),       // Icono
                ),
                validator: (value) {
                  // Valida que no esté vacío y contenga '@'
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu email';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null; // Campo válido
                },
              ),

              const SizedBox(height: 16),

              // === Campo de Contraseña ===
              TextFormField(
                controller: _passCtrl,                 // Vincula el controlador
                obscureText: true,                     // Oculta el texto
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  // Valida longitud mínima
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null; // Campo válido
                },
              ),

              const SizedBox(height: 24),

              // === Mensaje de error ===
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 8),

              // === Botón de envío ===
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
