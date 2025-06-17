import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/';
  // Agrega más rutas aquí

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const Placeholder());
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Ruta no encontrada'))));
    }
  }
}