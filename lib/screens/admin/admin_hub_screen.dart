import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:gymtrack_app/screens/admin/users/users_admin_screen.dart';
import 'package:gymtrack_app/screens/admin/routines/routines_admin_screen.dart';
import 'package:gymtrack_app/screens/auth/login_screen.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
        final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        centerTitle: true,
         actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (e) {
                  // no bloquear la navegación por un fallo al cerrar sesión
                }
                // Llevar al LoginScreen y limpiar la pila
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _AdminCard(
              icon: Icons.people,
              title: 'Gestión de Usuarios',
              subtitle: 'Altas, bajas y edición',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersAdminScreen()));
              },
            ),
            _AdminCard(
              icon: Icons.fitness_center,
              title: 'Gestión de Rutinas',
              subtitle: 'Crear y editar plantillas',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutinesAdminScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}