import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pantalla para recuperación de contraseña (RF3)
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });

    final email = _emailCtrl.text.trim().toLowerCase();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _message = 'Si el correo existe en el sistema, recibirás un email para restablecer la contraseña.';
      });
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          setState(() {
            _message = 'El correo ingresado no es válido.';
          });
          break;
        case 'user-not-found':
          setState(() {
            _message = 'Si el correo existe en el sistema, recibirás un email para restablecer la contraseña.';
          });
          break;
        case 'too-many-requests':
          setState(() {
            _message = 'Demasiados intentos. Por favor, inténtalo más tarde.';
          });
          break;
        default:
          setState(() {
            _message = 'Error inesperado: ${e.message}';
          });
      }
    } catch (e) {
      setState(() {
        _message = 'Error de red o inesperado. Inténtalo de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu correo para recibir un enlace de restablecimiento',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo';
                  }
                  if (!value.contains('@')) {
                    return 'Formato de correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.startsWith('Si el correo') ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _loading ? null : _sendReset,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enviar'),
              ),
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Volver al Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
