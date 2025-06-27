import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crea un nuevo usuario en Auth y Firestore
  Future<void> registrarUsuario({
    required String email,
    required String password,
    required Usuario usuario,
  }) async {
    try {
      // 1. Crear el usuario en Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = cred.user!.uid;

      // 2. Guardar el usuario en Firestore (colección "usuarios")
      await _firestore.collection('usuarios').doc(uid).set(usuario.toMap());

    } on FirebaseAuthException catch (e) {
      // Manejo de errores comunes
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      // Otros errores
      throw Exception('Error al registrar usuario: $e');
    }
  }
}
