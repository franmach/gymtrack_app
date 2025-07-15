import 'dart:convert';

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
  List<EjercicioAsignado> _exercises = [];
  late List<TextEditingController> _doneCtrls;
  late List<bool> _completed;
  late List<bool> _incomplete;
  late SharedPreferences _prefs;
  final _localKey = 'session_partial';

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
    final list = await widget.service.fetchExercisesForDay(widget.userId, widget.day);
    _doneCtrls = List.generate(list.length, (_) => TextEditingController());
    _completed = List.filled(list.length, false);
    _incomplete = List.filled(list.length, false);
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
    for (var c in _doneCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _finishSession() async {
    for (int i = 0; i < _exercises.length; i++) {
      if (!_completed[i] && !_incomplete[i]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marca completado o incompleto para "${_exercises[i].nombre}"')),
        );
        return;
      }
    }

    final doc = {
      'userId': widget.userId,
      'day': widget.day,
      'date': Timestamp.now(),
      'exercises': List.generate(_exercises.length, (i) {
        final e = _exercises[i];
        return {
          'nombre': e.nombre,
          'grupoMuscular': e.grupoMuscular,
          'series': e.series,
          'repsPlanificadas': e.repeticiones,
          'repsRealizadas': int.tryParse(_doneCtrls[i].text) ?? 0,
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
        const SnackBar(content: Text('Sin conexión: sesión guardada localmente')),
      );
    } else {
      await FirebaseFirestore.instance.collection('sesiones').add(doc);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión guardada exitosamente')),
      );
    }
    await _prefs.remove(_localKey);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final allChecked = _exercises.isNotEmpty && List.generate(_exercises.length, (i) => _completed[i] || _incomplete[i]).every((v) => v);

    return Scaffold(
      appBar: AppBar(title: Text('Sesión de ${widget.day}')),
      body: _exercises.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exercises.length,
                    itemBuilder: (_, i) {
                      final e = _exercises[i];
                      final locked = _completed[i] || _incomplete[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(e.grupoMuscular, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Series: ${e.series}'),
                                      Text('Reps: ${e.repeticiones}'),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: TextField(
                                      controller: _doneCtrls[i],
                                      enabled: !locked,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(
                                        labelText: 'Rep. totales realizadas',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      ),
                                      onChanged: (_) => _savePartial(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      const Text('Completado'),
                                      Checkbox(
                                        value: _completed[i],
                                        onChanged: (val) {
                                          setState(() {
                                            _completed[i] = val!;
                                            if (val) _incomplete[i] = false;
                                          });
                                          _savePartial();
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      const Text('Incompleto'),
                                      Checkbox(
                                        value: _incomplete[i],
                                        onChanged: (val) {
                                          setState(() {
                                            _incomplete[i] = val!;
                                            if (val) _completed[i] = false;
                                          });
                                          _savePartial();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: allChecked ? _finishSession : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Entrenamiento finalizado'),
                  ),
                ),
              ],
            ),
    );
  }
}