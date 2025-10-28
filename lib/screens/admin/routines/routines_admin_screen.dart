import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymtrack_app/screens/auth/login_screen.dart';

class RoutinesAdminScreen extends StatefulWidget {
  const RoutinesAdminScreen({super.key});

  @override
  State<RoutinesAdminScreen> createState() => _RoutinesAdminScreenState();
}

class _RoutinesAdminScreenState extends State<RoutinesAdminScreen> {
  final _col = FirebaseFirestore.instance.collection('rutinas');
  String _query = '';
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  Widget build(BuildContext context) {
        final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Gestión de Rutinas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
         actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (e) {
                  // no bloquear la navegación por un fallo al cerrar sesión
                }
                // Llevar al LoginScreen y limpiar la pila
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.snapshots(),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    hintText: 'Buscar rutina...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white24, width: 1),
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: PaginatedDataTable(
                        header: const Text(
                          'Rutinas',
                          style: TextStyle(color: Colors.white),
                        ),
                        rowsPerPage: _rowsPerPage,
                        onRowsPerPageChanged: (v) {
                          if (v != null) setState(() => _rowsPerPage = v);
                        },
                        columnSpacing: 24,
                        horizontalMargin: 16,
                        showFirstLastButtons: true,
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
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4cff00),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const _RoutineEditorDialog(),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
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
            IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => onEdit(d)),
            IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                onPressed: () => onDuplicate(d)),
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => onDelete(d)),
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
  final _col = FirebaseFirestore.instance.collection('rutinas');

  late final TextEditingController _nombre;
  late final TextEditingController _objetivo;
  String _nivel = 'Principiante (0–1 año)';
  int _dias = 3;
  List<Map<String, dynamic>> _ejercicios = [];

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _objetivo = TextEditingController(text: widget.initial?['objetivo'] ?? '');
    _nivel = widget.initial?['nivel'] ?? 'Principiante (0–1 año)';
    _dias = (widget.initial?['dias'] ?? 3) as int;

    final ejerciciosRaw = widget.initial?['ejercicios'];
    if (ejerciciosRaw is List) {
      _ejercicios = ejerciciosRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      _ejercicios = [];
    }
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
      await _col.doc(widget.routineId!).update(data);
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
                [
                  'Principiante (0–1 año)',
                  'Intermedio (1–3 años)',
                  'Avanzado (3+ años)',
                ],
                (v) => setState(() => _nivel = v),
              ),
              _dropdownInt(
                'Días por semana',
                _dias,
                7,
                (v) => setState(() => _dias = v),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ejercicios',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ..._ejercicios.asMap().entries.map((entry) {
                final index = entry.key;
                final ex = entry.value;
                return Card(
                  color: const Color(0xFF1A1A1A),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _innerField('Nombre del ejercicio', ex['nombre'] ?? '',
                            (v) => ex['nombre'] = v),
                        Row(
                          children: [
                            Expanded(
                              child: _innerField('Series', '${ex['series'] ?? 0}',
                                  (v) => ex['series'] = int.tryParse(v) ?? 0,
                                  number: true),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _innerField(
                                  'Repeticiones', '${ex['reps'] ?? 0}',
                                  (v) =>
                                      ex['reps'] = int.tryParse(v) ?? 0,
                                  number: true),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _innerField(
                                  'Peso (kg)', '${ex['peso'] ?? 0}',
                                  (v) => ex['peso'] =
                                      double.tryParse(v) ?? 0.0,
                                  number: true),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => _ejercicios.removeAt(index));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Agregar ejercicio',
                    style: TextStyle(color: Colors.white)),
                onPressed: _addExercise,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white70))),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4cff00)),
          child: const Text('Guardar', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

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
        value: value,
        items: List.generate(
          max,
          (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
        ),
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
        keyboardType:
            number ? TextInputType.number : TextInputType.text,
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
