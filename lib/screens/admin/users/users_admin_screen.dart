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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('nombre', descending: false).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error al cargar: ${snap.error}'));
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

          // Layout estable y fluido
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    hintText: 'Buscar por nombre o email...',
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
                  onChanged: _onSearchChanged,
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
                          'Usuarios',
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
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Teléfono')),
                          DataColumn(label: Text('Activo')),
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
            builder: (_) => const UserEditorDialog(),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
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
            activeColor: const Color(0xFF4cff00),
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
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => onEdit(d),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
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
      text: (widget.initial?['lesiones'] as List<dynamic>?)?.join(', ') ?? '',
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
      'disponibilidadSemanal':
          int.tryParse(_disponibilidadSemanal.text.trim()) ?? 0,
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
      'role': _rol == 'admin' ? 'admin' : 'user',
      'activo': _activo,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.userId == null) {
        await _col.add(data);
      } else {
        await _col.doc(widget.userId!).update(data);
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
      backgroundColor: const Color(0xFF111111),
      title: Text(
        widget.userId == null ? 'Nuevo Usuario' : 'Editar Usuario',
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _field('Nombre', _nombre, required: true),
                _field('Apellido', _apellido),
                _field('Email', _email,
                    required: true,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Email inválido' : null),
                _field('Edad', _edad, type: TextInputType.number),
                Row(
                  children: [
                    Expanded(child: _field('Peso (kg)', _peso, type: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('Altura (cm)', _altura, type: TextInputType.number)),
                  ],
                ),
                _field('Disponibilidad semanal (días)', _disponibilidadSemanal,
                    type: TextInputType.number),
                _field('Minutos por sesión', _minPorSesion, type: TextInputType.number),
                _dropdown('Nivel de experiencia', _nivelExperiencia, [
                  'Principiante (0–1 año)',
                  'Intermedio (1–3 años)',
                  'Avanzado (3+ años)',
                ], (v) => setState(() => _nivelExperiencia = v)),
                _field('Objetivo', _objetivo),
                _dropdown('Género', _genero, ['Masculino', 'Femenino', 'Otro'],
                    (v) => setState(() => _genero = v)),
                _field('Lesiones (separadas por coma)', _lesiones),
                _dropdown('Rol', _rol, ['alumno', 'admin', 'entrenador'],
                    (v) => setState(() => _rol = v)),
                SwitchListTile(
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                  title: const Text('Activo', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4cff00)),
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
        validator: validator ?? (required ? (v) => (v!.isEmpty ? 'Requerido' : null) : null),
      ),
    );
  }

  Widget _dropdown(
      String label, String value, List<String> items, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v),
                ))
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
}
