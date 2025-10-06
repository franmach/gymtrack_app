import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoutinesAdminScreen extends StatefulWidget {
  const RoutinesAdminScreen({super.key});

  @override
  State<RoutinesAdminScreen> createState() => _RoutinesAdminScreenState();
}

class _RoutinesAdminScreenState extends State<RoutinesAdminScreen> {
  final _col = FirebaseFirestore.instance.collection('rutinas_plantillas');
  String _query = '';
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Rutinas')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('nombre').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No hay rutinas registradas'));
          }

          final docs = snap.data!.docs.where((d) {
            if (_query.isEmpty) return true;
            final m = d.data();
            final nombre = (m['nombre'] ?? '').toString().toLowerCase();
            final objetivo = (m['objetivo'] ?? '').toString().toLowerCase();
            return nombre.contains(_query) || objetivo.contains(_query);
          }).toList();

          final source = _RoutinesTableSource(
            docs: docs,
            onEdit: (doc) => showDialog(
              context: context,
              builder: (_) =>
                  _RoutineEditorDialog(routineId: doc.id, initial: doc.data()),
            ),
            onDuplicate: (doc) async {
              final data = doc.data();
              final newData = {...data, 'nombre': '${data['nombre']} (copia)'};
              await _col.add(newData);
            },
            onDelete: (doc) async {
              final nombre = doc['nombre'] ?? '(sin nombre)';
              final assigned = await FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('rutinaPlantillaId', isEqualTo: doc.id)
                  .get();
              if (assigned.docs.isNotEmpty) {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Rutina en uso'),
                    content: Text(
                        'La rutina "$nombre" está asignada a ${assigned.docs.length} usuario(s). '
                        'Si la eliminas, dejarán de tenerla asociada. ¿Continuar?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar')),
                    ],
                  ),
                );
                if (ok != true) return;
              }
              await _col.doc(doc.id).delete();
            },
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar rutina...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: PaginatedDataTable(
                    header: const Text('Rutinas'),
                    rowsPerPage: _rowsPerPage,
                    onRowsPerPageChanged: (v) {
                      if (v != null) setState(() => _rowsPerPage = v);
                    },
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Objetivo')),
                      DataColumn(label: Text('Nivel')),
                      DataColumn(label: Text('Días')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    source: source,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const _RoutineEditorDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RoutinesTableSource extends DataTableSource {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onEdit;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onDuplicate;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onDelete;

  _RoutinesTableSource({
    required this.docs,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= docs.length) return null;
    final d = docs[index];
    final m = d.data();
    final nombre = (m['nombre'] ?? '').toString();
    final objetivo = (m['objetivo'] ?? '').toString();
    final nivel = (m['nivel'] ?? '').toString();
    final dias = (m['dias'] ?? 0).toString();

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(nombre)),
        DataCell(Text(objetivo)),
        DataCell(Text(nivel)),
        DataCell(Text(dias)),
        DataCell(Row(
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(d)),
            IconButton(
                icon: const Icon(Icons.copy), onPressed: () => onDuplicate(d)),
            IconButton(
                icon: const Icon(Icons.delete), onPressed: () => onDelete(d)),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => docs.length;

  @override
  int get selectedRowCount => 0;
}

class _RoutineEditorDialog extends StatefulWidget {
  final String? routineId;
  final Map<String, dynamic>? initial;
  const _RoutineEditorDialog({this.routineId, this.initial});

  @override
  State<_RoutineEditorDialog> createState() => _RoutineEditorDialogState();
}

class _RoutineEditorDialogState extends State<_RoutineEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _col = FirebaseFirestore.instance.collection('rutinas_plantillas');

  late final TextEditingController _nombre;
  late final TextEditingController _objetivo;
  String _nivel = 'Principiante';
  int _dias = 3;
  List<Map<String, dynamic>> _ejercicios = [];

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _objetivo = TextEditingController(text: widget.initial?['objetivo'] ?? '');
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
      title: Text(widget.routineId == null ? 'Nueva Rutina' : 'Editar Rutina'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _objetivo,
                decoration: const InputDecoration(labelText: 'Objetivo'),
              ),
              DropdownButtonFormField<String>(
                value: _nivel,
                decoration: const InputDecoration(labelText: 'Nivel'),
                items: const [
                  DropdownMenuItem(value: 'Principiante', child: Text('Principiante')),
                  DropdownMenuItem(value: 'Intermedio', child: Text('Intermedio')),
                  DropdownMenuItem(value: 'Avanzado', child: Text('Avanzado')),
                ],
                onChanged: (v) => setState(() => _nivel = v ?? 'Principiante'),
              ),
              DropdownButtonFormField<int>(
                value: _dias,
                decoration: const InputDecoration(labelText: 'Días por semana'),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
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
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: ex['nombre'],
                            decoration: const InputDecoration(labelText: 'Nombre del ejercicio'),
                            onChanged: (v) => ex['nombre'] = v,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: ex['series'].toString(),
                                  decoration: const InputDecoration(labelText: 'Series'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => ex['series'] = int.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: ex['reps'].toString(),
                                  decoration: const InputDecoration(labelText: 'Repeticiones'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => ex['reps'] = int.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: ex['peso'].toString(),
                                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => ex['peso'] = double.tryParse(v) ?? 0,
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}