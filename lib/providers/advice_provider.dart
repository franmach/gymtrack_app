import 'package:flutter/material.dart';
import '../models/educational_advice.dart';
import '../services/advice_service.dart';

/// Provider/Controller para exponer consejos a la UI y ejecutar generación.
/// Usa ChangeNotifier para acciones y expone streams directos para datos en tiempo real.
class AdviceProvider extends ChangeNotifier {
  final AdviceService _service;

  AdviceProvider({AdviceService? service}) : _service = service ?? AdviceService();

  /// Genera consejos vía IA y los guarda para `userId`.
  Future<void> generateForUser(String userId, {List<String> categorias = const ['nutricion', 'lesiones', 'habitos']}) async {
    await _service.generateAdviceForUser(userId, categorias: categorias);
    notifyListeners();
  }

  /// Método puntual para obtener consejos (no reactivo).
  Future<List<EducationalAdvice>> fetchAdvices(String userId) => _service.getUserAdvices(userId);

  /// Stream en tiempo real para desplegar en UI.
  Stream<List<EducationalAdvice>> streamAdvices(String userId) => _service.streamUserAdvices(userId);
}