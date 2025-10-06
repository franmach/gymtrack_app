import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  final _col = FirebaseFirestore.instance.collection('usuarios');
  String _query = '';
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = value.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('nombre', descending: false).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error al cargar: ${snap.error}'),
            );
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          final docs = snap.data!.docs.where((d) {
            if (_query.isEmpty) return true;
            final m = d.data();
            final nombre = (m['nombre'] ?? '').toString().toLowerCase();
            final email = (m['email'] ?? '').toString().toLowerCase();
            return nombre.contains(_query) || email.contains(_query);
          }).toList();

          final source = _UsersTableSource(
            docs: docs,
            onEdit: (doc) {
              showDialog(
                context: context,
                builder: (_) =>
                    UserEditorDialog(userId: doc.id, initial: doc.data()),
              );
            },
            onDelete: (doc) async {
              final nombre = doc['nombre'] ?? '(sin nombre)';
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Eliminar usuario'),
                  content: Text('¿Eliminar el perfil de "$nombre"?'),
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
              if (ok == true) {
                await _col.doc(doc.id).delete();
              }
            },
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre o email...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged, // 👈 debounce solo al tipear
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: PaginatedDataTable(
                    header: const Text('Usuarios'),
                    rowsPerPage: _rowsPerPage,
                    onRowsPerPageChanged: (v) {
                      if (v != null) setState(() => _rowsPerPage = v);
                    },
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Teléfono')),
                      DataColumn(label: Text('Activo')),
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
            builder: (_) => const UserEditorDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _UsersTableSource extends DataTableSource {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onEdit;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onDelete;

  _UsersTableSource({
    required this.docs,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= docs.length) return null;
    final d = docs[index];
    final m = d.data();
    final nombre = (m['nombre'] ?? '').toString();
    final email = (m['email'] ?? '').toString();
    final telefono = (m['telefono'] ?? '').toString();
    final activo = (m['activo'] ?? true) as bool;

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(nombre)),
        DataCell(Text(email)),
        DataCell(Text(telefono)),
        DataCell(
          Switch(
            value: activo,
            onChanged: (v) {
              FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(d.id)
                  .update({'activo': v});
            },
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => onEdit(d),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => onDelete(d),
              ),
            ],
          ),
        ),
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

class UserEditorDialog extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? initial;

  const UserEditorDialog({super.key, this.userId, this.initial});

  @override
  State<UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<UserEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _col = FirebaseFirestore.instance.collection('usuarios');

  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _email;
  late final TextEditingController _edad;
  late final TextEditingController _peso;
  late final TextEditingController _altura;
  late final TextEditingController _disponibilidadSemanal;
  late final TextEditingController _minPorSesion;
  late final TextEditingController _objetivo;
  late final TextEditingController _lesiones;
  String _nivelExperiencia = 'Principiante (0–1 año)';
  String _genero = 'Otro';
  String _rol = 'alumno';
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _apellido = TextEditingController(text: widget.initial?['apellido'] ?? '');
    _email = TextEditingController(text: widget.initial?['email'] ?? '');
    _edad = TextEditingController(text: (widget.initial?['edad']?.toString() ?? ''));
    _peso = TextEditingController(text: (widget.initial?['peso']?.toString() ?? ''));
    _altura = TextEditingController(text: (widget.initial?['altura']?.toString() ?? ''));
    _disponibilidadSemanal = TextEditingController(text: (widget.initial?['disponibilidadSemanal']?.toString() ?? ''));
    _minPorSesion = TextEditingController(text: (widget.initial?['minPorSesion']?.toString() ?? ''));
    _objetivo = TextEditingController(text: widget.initial?['objetivo'] ?? '');
    _lesiones = TextEditingController(
      text: (widget.initial?['lesiones'] as List<dynamic>?)
              ?.join(', ') ??
          '',
    );
    _nivelExperiencia = widget.initial?['nivelExperiencia'] ?? 'Principiante (0–1 año)';
    _genero = widget.initial?['genero'] ?? 'Otro';
    _rol = widget.initial?['rol'] ?? 'alumno';
    _activo = widget.initial?['activo'] ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _email.dispose();
    _edad.dispose();
    _peso.dispose();
    _altura.dispose();
    _disponibilidadSemanal.dispose();
    _minPorSesion.dispose();
    _objetivo.dispose();
    _lesiones.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre': _nombre.text.trim(),
      'apellido': _apellido.text.trim(),
      'email': _email.text.trim(),
      'edad': int.tryParse(_edad.text.trim()) ?? 0,
      'peso': double.tryParse(_peso.text.trim()) ?? 0.0,
      'altura': double.tryParse(_altura.text.trim()) ?? 0.0,
      'disponibilidadSemanal': int.tryParse(_disponibilidadSemanal.text.trim()) ?? 0,
      'minPorSesion': int.tryParse(_minPorSesion.text.trim()) ?? 0,
      'nivelExperiencia': _nivelExperiencia,
      'objetivo': _objetivo.text.trim(),
      'genero': _genero,
      'lesiones': _lesiones.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'rol': _rol,
      'activo': _activo,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.userId == null) {
        await _col.add(data);
      } else {
        await _col.doc(widget.userId).update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.userId == null ? 'Nuevo Usuario' : 'Editar Usuario'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _apellido,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                TextFormField(
                  controller: _edad,
                  decoration: const InputDecoration(labelText: 'Edad'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _peso,
                        decoration: const InputDecoration(labelText: 'Peso (kg)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _altura,
                        decoration: const InputDecoration(labelText: 'Altura (cm)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _disponibilidadSemanal,
                  decoration:
                      const InputDecoration(labelText: 'Disponibilidad semanal (días)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _minPorSesion,
                  decoration: const InputDecoration(labelText: 'Minutos por sesión'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: _nivelExperiencia,
                  items: const [
                    DropdownMenuItem(value: 'Principiante (0–1 año)', child: Text('Principiante (0–1 año)')),
                    DropdownMenuItem(value: 'Intermedio (1–2 años)', child: Text('Intermedio (1–2 años)')),
                    DropdownMenuItem(value: 'Avanzado (3+ años)', child: Text('Avanzado (3+ años)')),
                  ],
                  onChanged: (v) => setState(() => _nivelExperiencia = v ?? 'Principiante (0–1 año)'),
                  decoration: const InputDecoration(labelText: 'Nivel de experiencia'),
                ),
                TextFormField(
                  controller: _objetivo,
                  decoration: const InputDecoration(labelText: 'Objetivo'),
                ),
                DropdownButtonFormField<String>(
                  value: _genero,
                  items: const [
                    DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                    DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                  onChanged: (v) => setState(() => _genero = v ?? 'Otro'),
                  decoration: const InputDecoration(labelText: 'Género'),
                ),
                TextFormField(
                  controller: _lesiones,
                  decoration: const InputDecoration(labelText: 'Lesiones (separadas por coma)'),
                ),
                DropdownButtonFormField<String>(
                  value: _rol,
                  items: const [
                    DropdownMenuItem(value: 'alumno', child: Text('Alumno')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    DropdownMenuItem(value: 'entrenador', child: Text('Entrenador')),
                  ],
                  onChanged: (v) => setState(() => _rol = v ?? 'alumno'),
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                SwitchListTile(
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                  title: const Text('Activo'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}