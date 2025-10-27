import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoutinesAdminScreen extends StatefulWidget {
  const RoutinesAdminScreen({super.key});

  @override
  State<RoutinesAdminScreen> createState() => _RoutinesAdminScreenState();
}

class _RoutinesAdminScreenState extends State<RoutinesAdminScreen> {
  final _usersCol = FirebaseFirestore.instance.collection('usuarios');
  String? _selectedUserId;
  String? _selectedUserName;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Rutinas')),
      body: Row(
        children: [
          // ---- PANEL IZQUIERDO: USUARIOS ----
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // 🔍 BUSCADOR DE USUARIOS
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar usuario...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim().toLowerCase()),
                  ),
                ),

                // 📋 LISTADO DE USUARIOS
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _usersCol.orderBy('nombre').snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Error: ${snap.error}'));
                      }

                      final allUsers = snap.data?.docs ?? [];
                      // 🔎 Filtro local por nombre o email
                      final filteredUsers = allUsers.where((doc) {
                        final data = doc.data();
                        final nombre =
                            (data['nombre'] ?? '').toString().toLowerCase();
                        final email =
                            (data['email'] ?? '').toString().toLowerCase();
                        return nombre.contains(_searchQuery) ||
                            email.contains(_searchQuery);
                      }).toList();

                      if (filteredUsers.isEmpty) {
                        return const Center(
                            child: Text('No se encontraron usuarios'));
                      }

                      return ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, i) {
                          final u = filteredUsers[i].data();
                          final selected =
                              filteredUsers[i].id == _selectedUserId;
                          return Card(
                            color: selected ? Colors.blue.shade100 : null,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(u['nombre'] ?? 'Sin nombre'),
                              subtitle: Text(u['email'] ?? ''),
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  _selectedUserId = filteredUsers[i].id;
                                  _selectedUserName = u['nombre'] ?? 'Usuario';
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ---- PANEL DERECHO: RUTINAS DEL USUARIO ----
          Expanded(
            flex: 3,
            child: _selectedUserId == null
                ? const Center(
                    child: Text(
                      'Seleccione un usuario para ver sus rutinas',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : _UserRoutinesList(
                    userId: _selectedUserId!,
                    userName: _selectedUserName ?? '',
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------
// LISTA DE RUTINAS POR USUARIO
// -----------------------------------------------
class _UserRoutinesList extends StatelessWidget {
  final String userId;
  final String userName;

  const _UserRoutinesList({
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final _col = FirebaseFirestore.instance.collection('rutinas');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.blueGrey.shade50,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Rutinas de $userName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.where('uid', isEqualTo: userId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Text('Error: ${snap.error}');
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No hay rutinas asignadas'));
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final r = docs[i].data();
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(r['nombre'] ?? ''),
                  subtitle: Text(
                    'Objetivo: ${r['objetivo'] ?? ''}\n'
                    'Nivel: ${r['nivel'] ?? ''} | Días: ${r['dias'] ?? ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => _RoutineEditorDialog(
                              routineId: docs[i].id,
                              initial: r,
                              userId: userId,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar rutina'),
                              content: Text(
                                  '¿Seguro que desea eliminar la rutina "${r['nombre']}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _col.doc(docs[i].id).delete();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => _RoutineEditorDialog(userId: userId),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// -----------------------------------------------
// EDITOR DE RUTINA
// -----------------------------------------------
class _RoutineEditorDialog extends StatefulWidget {
  final String? routineId;
  final String? userId;
  final Map<String, dynamic>? initial;

  const _RoutineEditorDialog({this.routineId, this.userId, this.initial});

  @override
  State<_RoutineEditorDialog> createState() => _RoutineEditorDialogState();
}

class _RoutineEditorDialogState extends State<_RoutineEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _col = FirebaseFirestore.instance.collection('rutinas');

  late final TextEditingController _nombre;
  late final TextEditingController _objetivo;
  String _nivel = 'Principiante';
  int _dias = 3;
  List<Map<String, dynamic>> _ejercicios = [];

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _objetivo =
        TextEditingController(text: widget.initial?['objetivo'] ?? '');
    _nivel = widget.initial?['nivel'] ?? 'Principiante';
    _dias = (widget.initial?['dias'] ?? 3) as int;
    _ejercicios = List<Map<String, dynamic>>.from(
        widget.initial?['ejercicios'] ?? <Map<String, dynamic>>[]);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre': _nombre.text.trim(),
      'objetivo': _objetivo.text.trim(),
      'nivel': _nivel,
      'dias': _dias,
      'usuarioId': widget.userId,
      'ejercicios': _ejercicios,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (widget.routineId == null) {
      await _col.add(data);
    } else {
      await _col.doc(widget.routineId).update(data);
    }

    if (mounted) Navigator.pop(context);
  }

  void _addExercise() {
    setState(() {
      _ejercicios.add({
        'nombre': '',
        'series': 3,
        'reps': 10,
        'peso': 0,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.routineId == null
          ? 'Nueva Rutina'
          : 'Editar Rutina'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _objetivo,
                decoration: const InputDecoration(labelText: 'Objetivo'),
              ),
              DropdownButtonFormField<String>(
                value: _nivel,
                decoration: const InputDecoration(labelText: 'Nivel'),
                items: const [
                  DropdownMenuItem(
                      value: 'Principiante (0-1 año)', child: Text('Principiante (0-1 año)')),
                  DropdownMenuItem(
                      value: 'Intermedio (1-3 años)', child: Text('Intermedio (1-3 años)')),
                  DropdownMenuItem(
                      value: 'Avanzado (3+ años)', child: Text('Avanzado (3+ años)')),
                ],
                onChanged: (v) => setState(() => _nivel = v ?? 'Principiante (0-1)'),
              ),
              DropdownButtonFormField<int>(
                value: _dias,
                decoration:
                    const InputDecoration(labelText: 'Días por semana'),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}'),
                  ),
                ),
                onChanged: (v) => setState(() => _dias = v ?? 3),
              ),
              const SizedBox(height: 16),
              const Text('Ejercicios',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _ejercicios.length,
                itemBuilder: (context, index) {
                  final ex = _ejercicios[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: ex['nombre'],
                            decoration: const InputDecoration(
                                labelText: 'Nombre del ejercicio'),
                            onChanged: (v) => ex['nombre'] = v,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: ex['series'].toString(),
                                  decoration: const InputDecoration(
                                      labelText: 'Series'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) =>
                                      ex['series'] = int.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: ex['reps'].toString(),
                                  decoration: const InputDecoration(
                                      labelText: 'Repeticiones'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) =>
                                      ex['reps'] = int.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: ex['peso'].toString(),
                                  decoration: const InputDecoration(
                                      labelText: 'Peso (kg)'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => ex['peso'] =
                                      double.tryParse(v) ?? 0,
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _ejercicios.removeAt(index);
                                });
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar ejercicio'),
                onPressed: _addExercise,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}