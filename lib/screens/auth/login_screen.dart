import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/screens/dashboard/dashboard_screen.dart';
import 'package:gymtrack_app/screens/admin/admin_hub_screen.dart';
import 'package:gymtrack_app/screens/auth/forgotPassword_screen.dart';
import 'package:gymtrack_app/screens/auth/register_screen.dart';
import 'package:gymtrack_app/screens/main_tabbed_screen.dart';

/// Pantalla de Login con Firebase Auth y navegación al Dashboard
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  // SnackBar estilizado local
  void _showSnack(
    String text, {
    required Color bg,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return; // <-- evita usar context si ya fue desmontado
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: duration,
        ),
      );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Revisá los campos', bg: Colors.amberAccent, icon: Icons.info_outline);
      return;
    }
    setState(() { _loading = true; _errorMessage = null; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return; // <-- chequeo extra tras await

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      final data = doc.data() ?? {};

      if (!mounted) return; // <-- antes de mostrar Snack/navegar

      _showSnack(
        'Sesión iniciada',
        bg: Color(0xFF4CFF00),
        icon: Icons.check_circle_outline,
        duration: const Duration(milliseconds: 1200),
      );

      final isAdmin = (data['role'] == 'admin') || (data['rol'] == 'admin');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => isAdmin ? const AdminHubScreen() : const MainTabbedScreen()),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          _errorMessage = 'Contraseña incorrecta';
          break;
        default:
          _errorMessage = e.message ?? 'Error de autenticación';
      }
      _showSnack(_errorMessage!, bg: Colors.redAccent, icon: Icons.error_outline);
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _showSnack(_errorMessage!, bg: Colors.redAccent, icon: Icons.error_outline);
    } finally {
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
            Image.asset('assets/images/2.png', height: 50),
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
                    Image.asset('assets/images/logo.png'),
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
