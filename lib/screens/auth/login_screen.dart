import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/screens/dashboard/dashboard_screen.dart';
import 'package:gymtrack_app/screens/admin/admin_hub_screen.dart';
import 'package:gymtrack_app/screens/auth/forgotPassword_screen.dart';
import 'package:gymtrack_app/screens/auth/register_screen.dart';

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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final snap = await ref.get();

      // Asegurar doc y role/rol por defecto si faltan (sin degradar admin)
      Map<String, dynamic> data = snap.data() ?? {};
      final hasRole = data.containsKey('role');
      final hasRol  = data.containsKey('rol');
      final alreadyAdmin = (data['role'] == 'admin') || (data['rol'] == 'admin');

      if (!snap.exists || !hasRole || !hasRol) {
        await ref.set({
          if (!snap.exists) 'email': _emailCtrl.text.trim(),
          if (!hasRole) 'role': alreadyAdmin ? 'admin' : 'user',
          if (!hasRol)  'rol': alreadyAdmin ? 'admin' : 'alumno',
          'activo': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        data = (await ref.get()).data() ?? {};
      }

      final isAdmin = (data['role'] == 'admin') || (data['rol'] == 'admin');
      if (isAdmin) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHubScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    } on FirebaseAuthException catch (e) {
      // 6) Manejamos errores de autenticación
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('/images/2.png', height: 50),
            const SizedBox(width: 20),
            Text('Iniciar Sesión', style: Theme.of(context).appBarTheme.titleTextStyle),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - kToolbarHeight,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo encima del formulario
                    Image.asset('/images/logo.png'),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                              if (value == null || value.isEmpty) return 'Ingresa tu email';
                              if (!value.contains('@')) return 'Email inválido';
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
                              if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                              if (value.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Mensaje de error
                          if (_errorMessage != null)
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          // Botón Entrar (centrado por la columna stretch)
                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Entrar'),
                          ),
                          const SizedBox(height: 8),
                          // Enlace de recuperación centrado
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                                  },
                                  child: const Text('¿Olvidaste tu contraseña?'),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                                  },
                                  child: const Text('Crear cuenta'),
                                ),
                              ],
                            ),
                          ),
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
