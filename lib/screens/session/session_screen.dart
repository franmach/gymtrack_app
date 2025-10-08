// ... imports existentes ...
import 'dart:convert';
import 'dart:async';
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
  bool _guardando = false; // <- declara la bandera aquí
  // Timer / cronómetro
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Duration get _elapsed => _stopwatch.elapsed;
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours}:${minutes}:${seconds}';
  }
  void _startTimer() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }
  void _stopTimer() {
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
  }
  void _resetTimer() {
    _stopwatch.reset();
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
  }
  void _updateCompletionStates() {
    for (int i = 0; i < _exercises.length; i++) {
      final e = _exercises[i];
      final repsRealizadas = int.tryParse(_doneCtrls[i].text) ?? 0;
      final pesoUsado = double.tryParse(_pesoCtrls[i].text) ?? 0;
      final repsPlanificadas = e.series * e.repeticiones;
      final pesoPlanificado = e.peso ?? 0;
      // Aceptar ≥ para reps y peso (si hay peso planificado)
      final isCompleted = repsRealizadas >= repsPlanificadas &&
          (pesoPlanificado == 0 || pesoUsado >= pesoPlanificado);
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
    // Iniciar el cronómetro al empezar la sesión (si quieres que empiece automáticamente)
    _startTimer();
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
    // limpiar timer/stopwatch
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _finishSession() async {
    if (_guardando) return; // evita doble envío
    setState(() => _guardando = true);
    try {
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
        // Asegurarnos de usar el UID actual del usuario autenticado
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no autenticado')),
          );
          setState(() => _guardando = false);
          return;
        }

        final doc = {
          'uid': currentUid, // <-- usar UID seguro aquí
          'day': widget.day,
          'date': Timestamp.now(),
          // guardar duración en minutos (redondeo hacia arriba si hay segundos)
          'duracionMin': _stopwatch.elapsed.inSeconds == 0 ? 0 : ((_stopwatch.elapsed.inSeconds + 59) ~/ 60),
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

        pending.add(json.encode(doc));
        await _prefs.setStringList('pending_sessions', pending);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin conexión: sesión guardada localmente')),
        );
        setState(() {
          _guardando = false;
        });
        return;
      } else {
        // incluir duracionMin también en el documento en línea
        final docToSave = {
          ...doc,
          'duracionMin': _stopwatch.elapsed.inSeconds == 0 ? 0 : ((_stopwatch.elapsed.inSeconds + 59) ~/ 60),
        };
        final docRef =
            await FirebaseFirestore.instance.collection('sesiones').add(docToSave);
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
    } catch (e) {
      // maneja errores si quieres
      rethrow;
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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
                      // Mostrar cronómetro y controles rápidos
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            Text(_formatDuration(_elapsed), style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: _stopwatch.isRunning ? _stopTimer : _startTimer,
                                  child: Text(_stopwatch.isRunning ? 'Pausar' : 'Iniciar'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: _resetTimer,
                                  child: const Text('Reiniciar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
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
                    onPressed: (allChecked && !_guardando) ? _finishSession : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _guardando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Entrenamiento finalizado'),
                  ),
                ),
              ],
            ),
    );
  }

  // Reemplaza TODO el método _buildExerciseCard por este:
  Widget _buildExerciseCard(int i) {
    final e = _exercises[i];
    final repsRealizadas = int.tryParse(_doneCtrls[i].text) ?? 0;
    final pesoUsado = double.tryParse(_pesoCtrls[i].text) ?? 0;
    final repsPlanificadas = e.series * e.repeticiones;
    final pesoPlanificado = e.peso ?? 0;

    final isCompleted = repsRealizadas >= repsPlanificadas &&
        (pesoPlanificado == 0 || pesoUsado >= pesoPlanificado);
    final isIncomplete =
        !isCompleted && (repsRealizadas > 0 || pesoUsado > 0);

    _completed[i] = isCompleted;
    _incomplete[i] = isIncomplete;

    final scheme = Theme.of(context).colorScheme;

    // SOLO cambiamos el color del borde según estado
    Color borderColor;
    double borderWidth;
    if (isCompleted) {
      borderColor = scheme.primary;
      borderWidth = 2;
    } else if (isIncomplete) {
      borderColor = scheme.error;
      borderWidth = 2;
    } else {
      borderColor = Colors.transparent; // <-- invisible
      borderWidth = 0;
    }
    final statusText = isCompleted
        ? 'Completado ✔'
        : isIncomplete
            ? 'Incompleto'
            : 'Pendiente';

    final statusColor = isCompleted
        ? scheme.primary
        : isIncomplete
            ? scheme.error
            : scheme.outline;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      // Mantenemos el shape sin color de fondo custom
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Fondo por defecto del tema (no lo alteramos)
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.nombre,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.fitness_center,
                    color: scheme.primary.withOpacity(.85), size: 20),
                const SizedBox(width: 6),
                Text(e.grupoMuscular),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text('Series: ${e.series}'),
                Text('Reps: ${e.repeticiones}'),
                if (e.peso != null && e.peso! > 0)
                  Text('Peso rec.: ${e.peso!.toStringAsFixed(2)} kg'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _doneCtrls[i],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Reps totales realizadas',
                      isDense: true,
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _savePartial();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (e.peso != null && e.peso! > 0)
                  Expanded(
                    child: TextField(
                      controller: _pesoCtrls[i],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Peso usado (kg)',
                        isDense: true,
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _savePartial();
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: (!isCompleted && !isIncomplete) ? Alignment.center : Alignment.center,
              child: (!isCompleted && !isIncomplete)
                  ? Text(
                      statusText,
                      style: TextStyle(
                        color: scheme.outline,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}