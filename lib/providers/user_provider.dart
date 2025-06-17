import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _nombre;

  String? get nombre => _nombre;

  void actualizarNombre(String nuevoNombre) {
    _nombre = nuevoNombre;
    notifyListeners();
  }
}