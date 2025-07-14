import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/main.dart'; // Importa HomeScreen para regresar al inicio
import 'package:gymtrack_app/screens/historial/historial_screen.dart';

/// DashboardScreen: Pantalla principal tras iniciar sesión
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Depuración: confirmar que el build se ejecuta
    print('✅ DashboardScreen.build() ejecutado');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ocupa sólo el espacio necesario
          children: [
            // Mensaje de bienvenida
            const Text(
              'Bienvenido al Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Botón Perfil (ejemplo)
            ElevatedButton(
              onPressed: () {
                // Navegación a pantalla de perfil (debe existir o comentar)
                Navigator.pushNamed(context, '/profile');
              },
              child: const Text('Perfil'),
            ),
            const SizedBox(height: 12),

            // Botón para acceder al historial de entrenamientos
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistorialScreen(),
                  ),
                );
              },
              child: const Text('Historial'),
            ),
            const SizedBox(height: 12),

            // Botón Configuraciones (ejemplo)
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              child: const Text('Configuraciones'),
            ),
            const SizedBox(height: 24),

            // Botón de Cerrar Sesión
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                // 1) Cerrar sesión de Firebase
                await FirebaseAuth.instance.signOut();

                // 2) Redirigir a HomeScreen y limpiar historial
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
