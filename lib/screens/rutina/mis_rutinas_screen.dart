import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/gymtrack_theme.dart';
import 'package:gymtrack_app/models/usuario.dart';
import 'package:gymtrack_app/services/generar_rutina_service.dart';
import 'package:gymtrack_app/screens/rutina/rutina_screen.dart';

class MisRutinasScreen extends StatefulWidget {
  const MisRutinasScreen({super.key});

  @override
  State<MisRutinasScreen> createState() => _MisRutinasScreenState();
}

class _MisRutinasScreenState extends State<MisRutinasScreen> {
  bool _loading = false;

  // SnackBar estilizado local
  void _showSnack(BuildContext context, String text,
      {required Color bg, IconData? icon, Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
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
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
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

  Future<void> _generarNuevaRutina(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() => _loading = true);
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
        gimnasioId: data['gimnasioId'] ?? '',
      );

      await RutinaService.generarRutinaDesdePerfil(usuario);

      if (!mounted) return;
      _showSnack(
        context,
        'Nueva rutina generada con éxito',
        bg: verdeFluor,
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        context,
        'Error al generar rutina',
        bg: Colors.redAccent,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
            onPressed: _loading ? null : () => _generarNuevaRutina(context),
          )
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
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
          if (_loading) ...[
            const ModalBarrier(dismissible: false, color: Colors.black45),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
