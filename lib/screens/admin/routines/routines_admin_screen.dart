import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Pantalla de Administración de Rutinas (por usuario)
class RoutinesAdminScreen extends StatefulWidget {
  const RoutinesAdminScreen({super.key});

  @override
  State<RoutinesAdminScreen> createState() => _RoutinesAdminScreenState();
}

class _RoutinesAdminScreenState extends State<RoutinesAdminScreen> {
  final _usersCol = FirebaseFirestore.instance.collection('usuarios');
  final _routinesCol = FirebaseFirestore.instance.collection('rutinas');

  String _userQuery = '';
  final _expandedUsers = <String>{}; // userIds expandidos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Gestión de Rutinas',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Buscador de usuarios
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                hintText: 'Buscar usuario...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24, width: 1),
                ),
                isDense: true,
              ),
              onChanged: (v) =>
                  setState(() => _userQuery = v.trim().toLowerCase()),
            ),
          ),

          // Lista de usuarios (con expansión para ver rutinas)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _usersCol.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: Colors.red)));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No hay usuarios',
                          style: TextStyle(color: Colors.white70)));
                }

                // Ordenar por username/nombre (cliente) y filtrar por búsqueda
                final users = snap.data!.docs.toList()
                  ..sort((a, b) {
                    final ma = a.data();
                    final mb = b.data();
                    final ua = (ma['username'] ?? ma['nombre'] ?? '')
                        .toString()
                        .toLowerCase();
                    final ub = (mb['username'] ?? mb['nombre'] ?? '')
                        .toString()
                        .toLowerCase();
                    return ua.compareTo(ub);
                  });

                final filtered = users.where((d) {
                  if (_userQuery.isEmpty) return true;
                  final m = d.data();
                  final userLabel = (m['username'] ?? m['nombre'] ?? '')
                      .toString()
                      .toLowerCase();
                  return userLabel.contains(_userQuery);
                }).toList();

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (context, i) {
                    final uDoc = filtered[i];
                    final u = uDoc.data();
                    final userId = uDoc.id;
                    final userLabel =
                        (u['username'] ?? u['nombre'] ?? userId).toString();
                    final isExpanded = _expandedUsers.contains(userId);

                    return Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (open) {
                          setState(() {
                            if (open) {
                              _expandedUsers.add(userId);
                            } else {
                              _expandedUsers.remove(userId);
                            }
                          });
                        },
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        collapsedBackgroundColor: const Color(0xFF0E0E0E),
                        backgroundColor: const Color(0xFF121212),
                        iconColor: Colors.white70,
                        collapsedIconColor: Colors.white70,
                        title: Text(userLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        subtitle: u.containsKey('email')
                            ? Text('${u['email']}',
                                style: const TextStyle(color: Colors.white54))
                            : null,
                        children: [
                          // Botón crear nueva rutina para este usuario
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: ElevatedButton.icon(
                                icon:
                                    const Icon(Icons.add, color: Colors.black),
                                label: const Text('Nueva rutina',
                                    style: TextStyle(color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4cff00)),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => RoutineEditorDialog(
                                      userId: userId,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Lista de rutinas del usuario
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _routinesCol
                                .where('uid', isEqualTo: userId)
                                .snapshots(),
                            builder: (context, rSnap) {
                              if (rSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: LinearProgressIndicator(minHeight: 2),
                                );
                              }
                              if (rSnap.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                      'Error al cargar rutinas: ${rSnap.error}',
                                      style: const TextStyle(
                                          color: Colors.redAccent)),
                                );
                              }
                              final rDocs = rSnap.data?.docs ?? [];
                              if (rDocs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Este usuario no tiene rutinas.',
                                      style: TextStyle(color: Colors.white54)),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: rDocs.length,
                                itemBuilder: (context, idx) {
                                  final rDoc = rDocs[idx];
                                  final r = rDoc.data();
                                  final nombre = (r['nombre'] ?? '(Sin nombre)')
                                      .toString();
                                  final objetivo =
                                      (r['objetivo'] ?? '').toString();
                                  final nivel = (r['nivel'] ?? '').toString();
                                  final dias =
                                      (r['dias_por_semana'] ?? r['dias'] ?? 0)
                                          .toString();

                                  return Card(
                                    color: const Color(0xFF1A1A1A),
                                    margin: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: ListTile(
                                      title: Text(nombre,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600)),
                                      subtitle: Text(
                                        [
                                          if (objetivo.isNotEmpty)
                                            'Objetivo: $objetivo',
                                          if (nivel.isNotEmpty) 'Nivel: $nivel',
                                          'Días/sem: $dias',
                                        ].join('  •  '),
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            tooltip: 'Editar',
                                            icon: const Icon(Icons.edit,
                                                color: Colors.white),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    RoutineEditorDialog(
                                                  userId: userId,
                                                  routineId: rDoc.id,
                                                  initial: r,
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: const Icon(Icons.delete,
                                                color: Colors.redAccent),
                                            onPressed: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  backgroundColor:
                                                      const Color(0xFF111111),
                                                  title: const Text(
                                                      'Eliminar rutina',
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                  content: Text(
                                                    '¿Seguro que deseas eliminar la rutina "$nombre"?',
                                                    style: const TextStyle(
                                                        color: Colors.white70),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text(
                                                          'Cancelar',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white70)),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFF4cff00)),
                                                      child: const Text(
                                                          'Eliminar',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok == true) {
                                                await _routinesCol
                                                    .doc(rDoc.id)
                                                    .delete();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo de creación/edición de una rutina
class RoutineEditorDialog extends StatefulWidget {
  final String userId;
  final String? routineId;
  final Map<String, dynamic>? initial;

  const RoutineEditorDialog({
    super.key,
    required this.userId,
    this.routineId,
    this.initial,
  });

  @override
  State<RoutineEditorDialog> createState() => _RoutineEditorDialogState();
}

class _RoutineEditorDialogState extends State<RoutineEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _col = FirebaseFirestore.instance.collection('rutinas');

  late final TextEditingController _nombre;
  late final TextEditingController _objetivo;
  String _nivel = 'Principiante (0–1 año)';
  int _diasPorSemana = 3;
  List<Map<String, dynamic>> _rutina = [];

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _objetivo = TextEditingController(text: widget.initial?['objetivo'] ?? '');
    _nivel = widget.initial?['nivel'] ?? 'Principiante (0–1 año)';
    final rawDias = widget.initial?['dias_por_semana'];
    if (rawDias is int) {
      _diasPorSemana = rawDias;
    } else if (rawDias is String) {
      _diasPorSemana = int.tryParse(rawDias) ?? 3;
    } else {
      _diasPorSemana = 3;
    }
    final rutinaRaw = widget.initial?['rutina'];
    if (rutinaRaw is List) {
      _rutina = rutinaRaw.map((r) => Map<String, dynamic>.from(r)).toList();
    } else {
      _rutina = [];
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  void _addDia() {
    setState(() {
      _rutina.add({
        'dia': 'Nuevo día',
        'ejercicios': [
          {
            'nombre': '',
            'series': 3,
            'repeticiones': '',
            'grupo_muscular': '',
            'descanso_segundos': 60,
          }
        ],
      });
    });
  }

  void _addEjercicio(int diaIndex) {
    setState(() {
      _rutina[diaIndex]['ejercicios'].add({
        'nombre': '',
        'series': 3,
        'repeticiones': '',
        'grupo_muscular': '',
        'descanso_segundos': 60,
      });
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'uid': widget.userId,
      'nombre': _nombre.text.trim(),
      'objetivo': _objetivo.text.trim(),
      'nivel': _nivel,
      'dias_por_semana': _diasPorSemana,
      'rutina': _rutina.map((r) {
        final ejercicios = (r['ejercicios'] ?? []) as List;
        return {
          'dia': r['dia'] ?? '',
          'ejercicios': ejercicios.map((e) {
            return {
              'nombre': e['nombre'] ?? '',
              'series': e['series'] ?? 0,
              'repeticiones': e['repeticiones'] ?? '',
              'grupo_muscular': e['grupo_muscular'] ?? '',
              'descanso_segundos': e['descanso_segundos'] ?? 60,
            };
          }).toList(),
        };
      }).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (widget.routineId == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    if (widget.routineId == null) {
      // Crear nueva rutina
      await _col.add(data);
    } else {
      // Actualizar existente
      await _col.doc(widget.routineId!).update(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: Text(
        widget.routineId == null ? 'Nueva Rutina' : 'Editar Rutina',
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Nombre', _nombre, required: true),
              _field('Objetivo', _objetivo),
              _dropdown(
                'Nivel',
                _nivel,
                const [
                  'Principiante (0–1 año)',
                  'Intermedio (1–3 años)',
                  'Avanzado (3+ años)',
                ],
                (v) => setState(() => _nivel = v),
              ),
              _dropdownInt(
                'Días por semana',
                _diasPorSemana,
                7,
                (v) => setState(() => _diasPorSemana = v),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rutina por día',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),

              // Listado de días
              ..._rutina.asMap().entries.map((entry) {
                final diaIndex = entry.key;
                final diaData = entry.value;
                final ejercicios = List<Map<String, dynamic>>.from(
                    diaData['ejercicios'] ?? []);

                return Card(
                  color: const Color(0xFF1A1A1A),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado del día
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: diaData['dia'] ?? '',
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Día',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFF4cff00)),
                                  ),
                                ),
                                onChanged: (v) => diaData['dia'] = v,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              tooltip: 'Eliminar día',
                              onPressed: () =>
                                  setState(() => _rutina.removeAt(diaIndex)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Ejercicios del día
                        ...ejercicios.asMap().entries.map((eEntry) {
                          final exIndex = eEntry.key;
                          final ex = eEntry.value;
                          return Card(
                            color: const Color(0xFF222222),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  _innerField(
                                      'Nombre del ejercicio',
                                      ex['nombre'] ?? '',
                                      (v) => ex['nombre'] = v),
                                  _innerField(
                                      'Grupo muscular',
                                      ex['grupo_muscular'] ?? '',
                                      (v) => ex['grupo_muscular'] = v),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _innerField(
                                            'Series',
                                            '${ex['series'] ?? ''}',
                                            (v) => ex['series'] =
                                                int.tryParse(v) ?? 0,
                                            number: true),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _innerField(
                                            'Repeticiones',
                                            '${ex['repeticiones'] ?? ''}',
                                            (v) => ex['repeticiones'] = v),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _innerField(
                                      'Descanso (seg)',
                                      '${ex['descanso_segundos'] ?? 60}',
                                      (v) => ex['descanso_segundos'] =
                                          int.tryParse(v) ?? 60,
                                      number: true),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      tooltip: 'Eliminar ejercicio',
                                      onPressed: () => setState(
                                          () => ejercicios.removeAt(exIndex)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Botón agregar ejercicio
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Agregar ejercicio',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () => _addEjercicio(diaIndex),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Botón agregar día
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Agregar día',
                    style: TextStyle(color: Colors.white)),
                onPressed: _addDia,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4cff00)),
          child: const Text('Guardar', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  // Helpers de UI
  Widget _field(String label, TextEditingController ctrl,
      {bool required = false,
      TextInputType type = TextInputType.text,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4cff00)),
          ),
        ),
        keyboardType: type,
        validator: validator ??
            (required ? (v) => (v!.isEmpty ? 'Requerido' : null) : null),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        items: items
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4cff00)),
          ),
        ),
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _dropdownInt(
      String label, int value, int max, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<int>(
        value: value.clamp(1, max),
        items: List.generate(max,
            (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4cff00)),
          ),
        ),
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _innerField(String label, String value, Function(String) onChanged,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: value,
        style: const TextStyle(color: Colors.white),
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4cff00)),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
// ---------- UI helpers ----------

Widget _field(String label, TextEditingController ctrl,
    {bool required = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4cff00)),
        ),
      ),
      keyboardType: type,
      validator: validator ??
          (required ? (v) => (v!.isEmpty ? 'Requerido' : null) : null),
    ),
  );
}

Widget _dropdown(String label, String value, List<String> items,
    Function(String) onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      items:
          items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4cff00)),
        ),
      ),
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
    ),
  );
}

Widget _dropdownInt(String label, int value, int max, Function(int) onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<int>(
      value: value.clamp(1, max),
      items: List.generate(
          max, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4cff00)),
        ),
      ),
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
    ),
  );
}

Widget _innerField(String label, String value, Function(String) onChanged,
    {bool number = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextFormField(
      initialValue: value,
      style: const TextStyle(color: Colors.white),
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4cff00)),
        ),
      ),
      onChanged: onChanged,
    ),
  );
}
