// ... imports existentes ...
import 'dart:convert';
import 'package:gymtrack_app/services/gamification_service.dart';
import 'package:gymtrack_app/services/gamification_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gymtrack_app/models/ejercicioAsignado.dart';
import 'package:gymtrack_app/services/routine_service.dart';

class SesionScreen extends StatefulWidget {
  final RoutineService service;
  final String userId;
  final String day;

  const SesionScreen({
    Key? key,
    required this.service,
    required this.userId,
    required this.day,
  }) : super(key: key);

  @override
  _SesionScreenState createState() => _SesionScreenState();
}

class _SesionScreenState extends State<SesionScreen> {
  void _updateCompletionStates() {
    for (int i = 0; i < _exercises.length; i++) {
      final e = _exercises[i];
      final repsRealizadas = int.tryParse(_doneCtrls[i].text) ?? 0;
      final pesoUsado = double.tryParse(_pesoCtrls[i].text) ?? 0;
      final repsPlanificadas = e.series * e.repeticiones;
      final pesoPlanificado = e.peso ?? 0;
      final isCompleted = repsRealizadas == repsPlanificadas &&
          (pesoPlanificado == 0 || pesoUsado == pesoPlanificado);
      final isIncomplete =
          !isCompleted && (repsRealizadas > 0 || pesoUsado > 0);
      _completed[i] = isCompleted;
      _incomplete[i] = isIncomplete;
    }
  }

  List<EjercicioAsignado> _exercises = [];
  late List<TextEditingController> _doneCtrls;
  late List<bool> _completed;
  late List<bool> _incomplete;
  late SharedPreferences _prefs;
  final _localKey = 'session_partial';
  final _comentarioGeneralCtrl = TextEditingController();
  late List<TextEditingController> _pesoCtrls;
  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadExercises();
    _loadPartial();
    Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) _syncPending();
    });
  }

  Future<void> _loadExercises() async {
    final list =
        await widget.service.fetchExercisesForDay(widget.userId, widget.day);
    _doneCtrls = List.generate(list.length, (_) => TextEditingController());
    _completed = List.filled(list.length, false);
    _incomplete = List.filled(list.length, false);
    _pesoCtrls = List.generate(list.length, (_) => TextEditingController());
    setState(() => _exercises = list);
  }

  void _loadPartial() {
    final jsonStr = _prefs.getString(_localKey);
    if (jsonStr == null) return;
    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final compList = List<bool>.from(data['completed']);
      final incompList = List<bool>.from(data['incomplete']);
      for (int i = 0; i < _exercises.length && i < compList.length; i++) {
        _completed[i] = compList[i];
        _incomplete[i] = incompList[i];
      }
      setState(() {});
    } catch (_) {}
  }

  void _savePartial() {
    _prefs.setString(
      _localKey,
      json.encode({
        'completed': _completed,
        'incomplete': _incomplete,
      }),
    );
  }

  Future<void> _syncPending() async {
    final pending = _prefs.getStringList('pending_sessions') ?? [];
    if (pending.isEmpty) return;
    for (var item in pending) {
      final data = json.decode(item) as Map<String, dynamic>;
      await FirebaseFirestore.instance.collection('sesiones').add(data);
    }
    await _prefs.remove('pending_sessions');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesiones pendientes sincronizadas')),
    );
  }

  @override
  void dispose() {
    for (var c in _doneCtrls) {
      c.dispose();
    }
    for (var c in _pesoCtrls) {
      c.dispose();
    }
    _comentarioGeneralCtrl.dispose();
    super.dispose();
  }

  Future<void> _finishSession() async {
    for (int i = 0; i < _exercises.length; i++) {
      if (!_completed[i] && !_incomplete[i]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Marca completado o incompleto para "${_exercises[i].nombre}"')),
        );
        return;
      }
    }

    final doc = {
      'uid': widget.userId,
      'day': widget.day,
      'date': Timestamp.now(),
      'comentario_general': _comentarioGeneralCtrl.text.trim(),
      'exercises': List.generate(_exercises.length, (i) {
        final e = _exercises[i];
        final pesoUsado = double.tryParse(_pesoCtrls[i].text);
        return {
          'nombre': e.nombre,
          'grupoMuscular': e.grupoMuscular,
          'series': e.series,
          'repsPlanificadas': e.series * e.repeticiones,
          'repsRealizadas': int.tryParse(_doneCtrls[i].text) ?? 0,
          'pesoPlanificado': e.peso,
          'peso_usado': (pesoUsado != null && pesoUsado > 0) ? pesoUsado : null,
          'completed': _completed[i],
          'incomplete': _incomplete[i],
        };
      }),
    };

    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      final pending = _prefs.getStringList('pending_sessions') ?? [];
      pending.add(json.encode(doc));
      await _prefs.setStringList('pending_sessions', pending);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sin conexión: sesión guardada localmente')),
      );
    } else {
      final docRef =
          await FirebaseFirestore.instance.collection('sesiones').add(doc);
      final sesionId = docRef.id;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión guardada exitosamente')),
      );
      // --- INTEGRACIÓN GAMIFICACIÓN ---
      final gamificationRepo = GamificationRepository(
          FirebaseFirestore.instance, FirebaseAuth.instance);
      final gamificationService = GamificationService(gamificationRepo);
      await gamificationService.onSesionCompletada(
          widget.userId, DateTime.now(),
          sesionId: sesionId);
      // --- FIN INTEGRACIÓN ---
    }

    await _prefs.remove(_localKey);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _updateCompletionStates();
    final allChecked = _exercises.isNotEmpty &&
        List.generate(_exercises.length, (i) => _completed[i] || _incomplete[i])
            .every((v) => v);

    return Scaffold(
      appBar: AppBar(title: Text('Sesión de ${widget.day}')),
      body: _exercises.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (int i = 0; i < _exercises.length; i++)
                        _buildExerciseCard(i),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _comentarioGeneralCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText:
                              'Comentario general de la sesión (opcional)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: allChecked ? _finishSession : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Entrenamiento finalizado'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExerciseCard(int i) {
    final e = _exercises[i];
    // Calcular si el ejercicio está completo/incompleto automáticamente
    final repsRealizadas = int.tryParse(_doneCtrls[i].text) ?? 0;
    final pesoUsado = double.tryParse(_pesoCtrls[i].text) ?? 0;
    final repsPlanificadas = e.series * e.repeticiones;
    final pesoPlanificado = e.peso ?? 0;
    final isCompleted = repsRealizadas == repsPlanificadas &&
        (pesoPlanificado == 0 || pesoUsado == pesoPlanificado);
    final isIncomplete = !isCompleted && (repsRealizadas > 0 || pesoUsado > 0);
    _completed[i] = isCompleted;
    _incomplete[i] = isIncomplete;

    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.nombre,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.fitness_center,
                    color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 6),
                Text(e.grupoMuscular, style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.format_list_numbered,
                    color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 6),
                Text('Series: ${e.series}',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                Icon(Icons.repeat,
                    color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 6),
                Text('Reps: ${e.repeticiones}',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                if (e.peso != null && e.peso! > 0)
                  Row(
                    children: [
                      Icon(Icons.fitness_center,
                          color: Theme.of(context).primaryColor, size: 22),
                      const SizedBox(width: 6),
                      Text('Peso recomendado: ${e.peso!.toStringAsFixed(2)} kg',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.fitness_center,
                    color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _doneCtrls[i],
                    enabled: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Rep. totales realizadas',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _savePartial();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Icono y campo solo si hay peso recomendado
                e.peso != null && e.peso! > 0
                    ? Icon(Icons.fitness_center,
                        color: Theme.of(context).primaryColor, size: 22)
                    : SizedBox.shrink(),
                e.peso != null && e.peso! > 0
                    ? const SizedBox(width: 6)
                    : SizedBox.shrink(),
                e.peso != null && e.peso! > 0
                    ? Expanded(
                        child: TextField(
                          controller: _pesoCtrls[i],
                          enabled: true,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Peso usado (kg)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                          ),
                          style: TextStyle(color: Colors.white),
                          onChanged: (_) {
                            setState(() {});
                            _savePartial();
                          },
                        ),
                      )
                    : SizedBox.shrink(),

                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text('Completado',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: isCompleted ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 20, color: Colors.black)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Text('Incompleto',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: isIncomplete ? Colors.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isIncomplete
                          ? const Icon(Icons.close,
                              size: 20, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
