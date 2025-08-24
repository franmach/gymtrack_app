import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/gymtrack_theme.dart';
import 'package:gymtrack_app/models/usuario.dart';
import 'package:gymtrack_app/services/rutinas/rutina_service.dart';
import 'package:gymtrack_app/screens/rutina/rutina_screen.dart';

class MisRutinasScreen extends StatelessWidget {
  const MisRutinasScreen({super.key});

  Future<void> _generarNuevaRutina(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      final data = userDoc.data();

      if (data == null) throw Exception('Usuario no encontrado');

      final usuario = Usuario(
        uid: uid,
        nombre: data['nombre'] ?? '',
        apellido: data['apellido'] ?? '',
        email: data['email'] ?? '',
        edad: data['edad'] ?? 0,
        peso: (data['peso'] ?? 0).toDouble(),
        altura: (data['altura'] ?? 0).toDouble(),
        disponibilidadSemanal: data['disponibilidadSemanal'] ?? 3,
        minPorSesion: data['minPorSesion'] ?? 30,
        nivelExperiencia: data['nivelExperiencia'] ?? '',
        objetivo: data['objetivo'] ?? '',
        genero: data['genero'] ?? '',
        lesiones: (data['lesiones'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        rol: data['rol'] ?? 'alumno',
        fechaRegistro:
            DateTime.tryParse(data['fechaRegistro'] ?? '') ?? DateTime.now(),
      );

      await RutinaService.generarRutinaDesdePerfil(usuario);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nueva rutina generada con éxito')),
      );
    } catch (e) {
      print('Error al generar rutina: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al generar rutina')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _generarNuevaRutina(context),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rutinas')
            .where('uid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rutinas = snapshot.data!.docs;
          if (rutinas.isEmpty) {
            return const Center(child: Text('Aún no tienes rutinas'));
          }
          return ListView.builder(
            itemCount: rutinas.length,
            itemBuilder: (context, index) {
              final rutina = rutinas[index];
              return ListTile(
                title: Text(rutina['objetivo']),
                subtitle: Text(
                    'Generada el ${rutina['fecha_generacion'].split('T')[0]}'),
                trailing: rutina['es_actual'] == true
                    ? const Icon(Icons.star, color: verdeFluor)
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RutinaScreen(rutinaId: rutina.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
