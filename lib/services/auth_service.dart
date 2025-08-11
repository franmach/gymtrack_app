import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_basico.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 /// Crea un nuevo usuario en Firebase Auth
Future<UserCredential> registrarConEmail({
  required String email,
  required String password,
}) async {
  try {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred;
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'email-already-in-use':
        throw Exception('El correo ya está registrado');
      case 'invalid-email':
        throw Exception('El formato del correo no es válido');
      case 'weak-password':
        throw Exception('La contraseña es demasiado débil');
      default:
        throw Exception('Error de autenticación: ${e.message}');
    }
  } catch (e) {
    throw Exception('Error inesperado al registrar usuario: $e');
  }
}


  /// Guarda los datos básicos del usuario en Firestore
  Future<void> guardarUsuarioBasico(UsuarioBasico usuario) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(usuario.uid)
          .set(usuario.toMap());
    } catch (e) {
      throw Exception('Error al guardar datos en Firestore: $e');
    }
  }
}
