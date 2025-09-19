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
  bool _onlyActive = false;
  bool _loading = false;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            tooltip: 'Nuevo usuario (perfil Firestore)',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const _UserEditorDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra superior de búsqueda + filtro
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nombre o email...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Solo activos'),
                  selected: _onlyActive,
                  onSelected: (v) => setState(() => _onlyActive = v),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),

          // Listado (tabla paginada)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _col.orderBy('nombre', descending: false).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error al cargar usuarios:\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('Sin usuarios'));
                }

                // Filtro en memoria según búsqueda y "solo activos"
                final filtered = snap.data!.docs.where((d) {
                  final m = d.data();
                  if (_onlyActive && (m['activo'] == false)) return false;
                  if (_query.isEmpty) return true;
                  final nombre = (m['nombre'] ?? '').toString().toLowerCase();
                  final email  = (m['email']  ?? '').toString().toLowerCase();
                  return nombre.contains(_query) || email.contains(_query);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No hay coincidencias con tu búsqueda'));
                }

                final src = _UsersTableSource(
                  context: context,
                  docs: filtered,
                  onEdit: (doc) async {
                    await showDialog(
                      context: context,
                      builder: (_) => _UserEditorDialog(userId: doc.id, initial: doc.data()),
                    );
                  },
                  onDelete: (doc) async {
                    final data   = doc.data();
                    final nombre = (data['nombre'] ?? '(sin nombre)').toString();

                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Eliminar usuario'),
                        content: Text(
                          '¿Eliminar el perfil de "$nombre"?\n'
                          '(Solo Firestore; no elimina credenciales de Firebase Auth).',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                        ],
                      ),
                    );

                    if (ok == true) {
                      setState(() => _loading = true);
                      try {
                        await _col.doc(doc.id).delete();
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    }
                  },
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: PaginatedDataTable(
                    header: const Text('Listado de usuarios'),
                    rowsPerPage: _rowsPerPage,
                    onRowsPerPageChanged: (v) {
                      if (v != null) setState(() => _rowsPerPage = v);
                    },
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Teléfono')),
                      DataColumn(label: Text('Nivel')),
                      DataColumn(label: Text('Objetivo')),
                      DataColumn(label: Text('Activo')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    source: src,
                    showFirstLastButtons: true,
                    columnSpacing: 16,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersTableSource extends DataTableSource {
  final BuildContext context;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) onEdit;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) onDelete;

  _UsersTableSource({
    required this.context,
    required this.docs,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= docs.length) return null;
    final d = docs[index];
    final m = d.data();

    final nombre  = (m['nombre']  ?? '').toString();
    final email   = (m['email']   ?? '').toString();
    final telefono= (m['telefono']?? '').toString();
    final nivel   = (m['nivel']   ?? 'Principiante').toString();
    final objetivo= (m['objetivo']?? '').toString();
    final activo  = (m['activo']  ?? true) as bool;

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(nombre.isEmpty ? '(sin nombre)' : nombre)),
        DataCell(Text(email)),
        DataCell(Text(telefono)),
        DataCell(Text(nivel)),
        DataCell(Text(objetivo)),
        DataCell(
          Switch(
            value: activo,
            onChanged: (v) {
              FirebaseFirestore.instance.collection('usuarios').doc(d.id).update({'activo': v});
              notifyListeners();
            },
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit),
                onPressed: () => onEdit(d),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
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

/// ====== Editor (diálogo) ======
class _UserEditorDialog extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? initial;
  const _UserEditorDialog({this.userId, this.initial});

  @override
  State<_UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<_UserEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _col = FirebaseFirestore.instance.collection('usuarios');

  late final TextEditingController _nombre;
  late final TextEditingController _email;
  late final TextEditingController _telefono;
  late final TextEditingController _pesoKg;
  late final TextEditingController _alturaCm;
  String _nivel = 'Principiante';
  String _objetivo = '';
  bool _isAdmin = false;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre   = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _email    = TextEditingController(text: widget.initial?['email'] ?? '');
    _telefono = TextEditingController(text: widget.initial?['telefono'] ?? '');
    _pesoKg   = TextEditingController(text: (widget.initial?['pesoKg']?.toString() ?? ''));
    _alturaCm = TextEditingController(text: (widget.initial?['alturaCm']?.toString() ?? ''));
    _nivel    = (widget.initial?['nivel'] ?? 'Principiante') as String;
    _objetivo = (widget.initial?['objetivo'] ?? '') as String;
    _isAdmin  = (widget.initial?['isAdmin'] == true) || (widget.initial?['rol'] == 'admin');
    _activo   = widget.initial?['activo'] ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _telefono.dispose();
    _pesoKg.dispose();
    _alturaCm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final double? peso   = _pesoKg.text.trim().isEmpty ? null : double.tryParse(_pesoKg.text.trim());
    final int?    altura = _alturaCm.text.trim().isEmpty ? null : int.tryParse(_alturaCm.text.trim());

    final data = {
      'nombre':  _nombre.text.trim(),
      'email':   _email.text.trim(),
      'telefono':_telefono.text.trim(),
      'nivel':   _nivel,
      'objetivo':_objetivo.trim(),
      'pesoKg':  peso,
      'alturaCm':altura,
      'isAdmin': _isAdmin,
      'activo':  _activo,
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
      title: Text(widget.userId == null ? 'Nuevo usuario' : 'Editar usuario'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _telefono,
                  decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pesoKg,
                        decoration: const InputDecoration(labelText: 'Peso (kg) opcional'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _alturaCm,
                        decoration: const InputDecoration(labelText: 'Altura (cm) opcional'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _objetivo,
                  decoration: const InputDecoration(labelText: 'Objetivo (opcional)'),
                  onChanged: (v) => _objetivo = v,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isAdmin,
                  onChanged: (v) => setState(() => _isAdmin = v),
                  title: const Text('Administrador'),
                ),
                SwitchListTile(
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                  title: const Text('Activo'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nota: ABML sobre perfiles en Firestore. Para crear/eliminar credenciales de acceso usa backend/console de Firebase Auth.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
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