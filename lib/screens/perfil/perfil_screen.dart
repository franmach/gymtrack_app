import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/models/notificacion.dart';
import 'package:gymtrack_app/screens/notificacion/notificaciones_screen.dart';
import 'package:gymtrack_app/screens/rutina/mis_rutinas_screen.dart';
import 'package:gymtrack_app/screens/auth/login_screen.dart';
import 'package:intl/intl.dart';

import '../../services/gamification_repository.dart';
import '../../services/gamification_service.dart';
import '../historial/historial_screen.dart';
import 'achievements_screen.dart';
import '../../models/logro.dart';

class PerfilScreen extends StatefulWidget {
  final bool startEditing;
  const PerfilScreen({super.key, this.startEditing = false});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool modoEdicion = false;
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final pesoController = TextEditingController();
  final alturaController = TextEditingController();
  final disponibilidadController = TextEditingController();

  String? _objetivoEdit; // <-- nuevo
  static const List<String> _objetivosOpciones = [ // <-- opciones comunes
    'Ganar músculo',
    'Bajar de peso',
    'Tonificar',
    'Mejorar resistencia',
    'Perder grasa',
    'Mantener',
    'Rehabilitación',
  ];

  // Helper SnackBar simple (sin AppMessenger)
  void _snack(String msg, {Color bg = Colors.black87}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: bg,
        ),
      );
  }

  Future<void> _guardarPerfil(String uid) async {
    // Parseos seguros
    double? _toDouble(String s) =>
        double.tryParse(s.replaceAll(',', '.').trim());
    int? _toInt(String s) => int.tryParse(s.trim());

    final updates = <String, dynamic>{};

    final nombre = nombreController.text.trim();
    final apellido = apellidoController.text.trim();
    if (nombre.isNotEmpty) updates['nombre'] = nombre;
    if (apellido.isNotEmpty) updates['apellido'] = apellido;

    final peso = _toDouble(pesoController.text);
    final altura = _toDouble(alturaController.text);
    final disp = _toInt(disponibilidadController.text);
    if (peso != null) updates['peso'] = peso;
    if (altura != null) updates['altura'] = altura;
    if (disp != null) updates['disponibilidadSemanal'] = disp;
    if (_objetivoEdit != null && _objetivoEdit!.isNotEmpty) { // <-- guardar objetivo
      updates['objetivo'] = _objetivoEdit;
    }

    if (updates.isEmpty) {
      _snack('No hay cambios para guardar', bg: Colors.amber.shade300);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update(updates);
      // Opcional: reflejar nombre en FirebaseAuth
      final u = FirebaseAuth.instance.currentUser;
      if (u != null && nombre.isNotEmpty) {
        await u.updateDisplayName(nombre);
      }
      _snack('Perfil actualizado', bg: Colors.lightGreenAccent);
      setState(() => modoEdicion = false);
    } catch (e) {
      _snack('Error al guardar: $e', bg: Colors.redAccent);
    }
  }

  @override
  void initState() {
    super.initState();
    modoEdicion = widget.startEditing;
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    pesoController.dispose();
    alturaController.dispose();
    disponibilidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
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
      body: user == null
          ? const Center(child: Text('No hay usuario autenticado.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // Manejo de errores: si la consulta tiene un error (p.ej. permisos), mostramos mensaje
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          const Text('Error al cargar perfil',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(err.toString(), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docSnap = snapshot.data;
                if (docSnap == null || !docSnap.exists) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 48),
                          const SizedBox(height: 8),
                          const Text('Perfil no encontrado.'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final userData = docSnap.data() as Map<String, dynamic>?;
                // query para sesiones del último mes (reactivo)
                final desde = DateTime.now().subtract(const Duration(days: 30));
                final sesionesMesQuery = FirebaseFirestore.instance
                    .collection('sesiones')
                    .where('uid', isEqualTo: uid)
                    .where('date',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(desde));

                // Compatibilidad: construir mapa de stats con fallback
                final stats = <String, dynamic>{};
                if (userData != null) {
                  if (userData['statsResumen'] is Map) {
                    stats.addAll(
                        Map<String, dynamic>.from(userData['statsResumen']));
                  }
                  // campos planos (por si están en raíz)
                  if (userData.containsKey('rachaActual')) {
                    stats['rachaActual'] = userData['rachaActual'];
                  }
                  if (userData.containsKey('sesionesMes')) {
                    stats['sesionesMes'] = userData['sesionesMes'];
                  }
                  if (userData.containsKey('minutosMes')) {
                    stats['minutosMes'] = userData['minutosMes'];
                  }
                  if (userData.containsKey('progresoPorc')) {
                    stats['progresoPorc'] = userData['progresoPorc'];
                  }
                  if (userData.containsKey('puntos')) {
                    stats['puntos'] = userData['puntos'];
                  }
                  if (userData.containsKey('ultimaAsistencia')) {
                    stats['ultimaAsistencia'] = userData['ultimaAsistencia'];
                  }
                }

                final nombre = userData?['nombre'] ?? user.displayName ?? '';
                final email = user.email ?? '';
                final nivel = userData?['nivelExperiencia'] ?? '—';
                final objetivo = userData?['objetivo'] ?? '—';
                final imagenUrl = userData?['imagen_url'] ?? '';

                // inicializar controles si no estamos en modo edición
                if (!modoEdicion) {
                  nombreController.text = nombre;
                  apellidoController.text = userData?['apellido'] ?? '';
                  pesoController.text = (userData?['peso'] ?? '').toString();
                  alturaController.text =
                      (userData?['altura'] ?? '').toString();
                  disponibilidadController.text =
                      (userData?['disponibilidadSemanal'] ?? '').toString();
                  _objetivoEdit = (objetivo == '—') ? null : objetivo; // <-- sincroniza
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundImage: () {
                                if (imagenUrl == null || imagenUrl.isEmpty) {
                                  return const AssetImage(
                                          'assets/images/profile_placeholder.png')
                                      as ImageProvider;
                                }
                                // URL remota
                                if (imagenUrl.startsWith('http')) {
                                  return NetworkImage(imagenUrl);
                                }
                                // ruta local (file:// o path)
                                try {
                                  String path = imagenUrl;
                                  if (imagenUrl.startsWith('file://')) {
                                    path = Uri.parse(imagenUrl).toFilePath();
                                  }
                                  final f = File(path);
                                  if (f.existsSync()) return FileImage(f);
                                } catch (_) {}
                                // fallback
                                return const AssetImage(
                                        'assets/images/profile_placeholder.png')
                                    as ImageProvider;
                              }(),
                            ),
                            const SizedBox(height: 12),
                            Text(nombre,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 6),
                            Text('$nivel • $objetivo',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 800),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    // Fila 1
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(0, 56),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12),
                                            ),
                                            onPressed: () async {
                                              if (uid == null) return;
                                              if (!modoEdicion) {
                                                // Entrar en edición
                                                setState(() => modoEdicion = true);
                                              } else {
                                                // Guardar cambios
                                                await _guardarPerfil(uid);
                                              }
                                            },
                                            icon: Icon(modoEdicion
                                                ? Icons.check
                                                : Icons.edit),
                                            label: Text(modoEdicion
                                                ? 'Guardar'
                                                : 'Editar'),
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 56),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        const HistorialScreen()),
                                              );
                                            },
                                            icon: const Icon(Icons.history),
                                            label: const Text('Historial'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Fila 2
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 56),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12),
                                            ),
                                            onPressed: () {
                                              if (uid == null) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Usuario no autenticado')),
                                                );
                                                return;
                                              }
                                              final repo = GamificationRepository(
                                                  FirebaseFirestore.instance,
                                                  FirebaseAuth.instance);
                                              final service = GamificationService(
                                                  repo);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => AchievementsScreen(
                                                      uid: uid, repo: repo, service: service),
                                                ),
                                              );
                                            },
                                            child: Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.emoji_events),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Logros',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(0, 56),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ConfigNotificacionesScreen(usuarioId: uid!),
                                                ),
                                              );
                                            },
                                            child: Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.alarm_on_sharp),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment: Alignment.centerLeft,
                                                      child: const Text(
                                                        'Notificaciones',
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Botón que ocupa las 2 columnas (ancho completo)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.list, size: 30),
                                        label: const Text(
                                          'Mis rutinas',
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const MisRutinasScreen()),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Datos básicos (colapsable / edición)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Datos',
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 8),
                              if (!modoEdicion) ...[
                                ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(nombre),
                                  subtitle: Text(email),
                                ),
                                ListTile(
                                  leading:
                                      const Icon(Icons.align_horizontal_left),
                                  title: Text('Nivel'),
                                  subtitle: Text(nivel.toString()),
                                ),
                              ] else ...[
                                TextFormField(
                                    controller: nombreController,
                                    decoration: const InputDecoration(
                                        labelText: 'Nombre')),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: apellidoController,
                                    decoration: const InputDecoration(
                                        labelText: 'Apellido')),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: pesoController,
                                    keyboardType: TextInputType.number, // opcional
                                    decoration: const InputDecoration(
                                        labelText: 'Peso (kg)')),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: alturaController,
                                    keyboardType: TextInputType.number, // opcional
                                    decoration: const InputDecoration(
                                        labelText: 'Altura (cm)')),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: disponibilidadController,
                                    keyboardType: TextInputType.number, // opcional
                                    decoration: const InputDecoration(
                                        labelText: 'Disponibilidad semanal')),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>( // <-- nuevo campo Objetivo
                                  value: _objetivoEdit?.isNotEmpty == true ? _objetivoEdit : null,
                                  decoration: const InputDecoration(labelText: 'Objetivo'),
                                  items: _objetivosOpciones
                                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _objetivoEdit = v),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // KPIs resumen rápido (usamos un solo StreamBuilder para sesiones+minutos)
                      StreamBuilder<QuerySnapshot>(
                        stream: sesionesMesQuery.snapshots(),
                        builder: (context, sSnap) {
                          // valores por defecto mientras llega el stream
                          int sesiones = (stats['sesionesMes'] is num)
                              ? (stats['sesionesMes'] as num).toInt()
                              : 0;
                          int minutos = (stats['minutosMes'] is num)
                              ? (stats['minutosMes'] as num).toInt()
                              : 0;

                          if (sSnap.hasData) {
                            final docs = sSnap.data!.docs;
                            sesiones = docs.length;
                            minutos = 0;
                            for (final d in docs) {
                              final data = d.data() as Map<String, dynamic>;
                              final rawDur = data['duracionMin'] ??
                                  data['durationMin'] ??
                                  0;
                              if (rawDur is num)
                                minutos += rawDur.toInt();
                              else if (rawDur is String)
                                minutos += int.tryParse(rawDur) ?? 0;
                            }
                          }

                          // actualizar stats locales (no necesario para UI pero útil si se reutiliza)
                          stats['sesionesMes'] = sesiones;
                          stats['minutosMes'] = minutos;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: _kpiCard(
                                          'Racha',
                                          stats['rachaActual']?.toString() ??
                                              '0',
                                          Icons.local_fire_department)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: _kpiCard(
                                          'Sesiones (mes)',
                                          sesiones.toString(),
                                          Icons.calendar_month)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _kpiCard('Minutos (mes)',
                                        minutos.toString(), Icons.timer),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: _kpiCard(
                                          'Puntos',
                                          stats['puntos']?.toString() ?? '0',
                                          Icons.emoji_events)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Últimas sesiones
                      const Divider(),
                      Text('Últimas sesiones',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (uid != null)
                        _buildRecentSessions(uid)
                      else
                        const SizedBox(),
                      const SizedBox(height: 16),

                      // Logros recientes
                      const Divider(),
                      Text('Logros recientes',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (uid != null)
                        _buildRecentAchievements(uid)
                      else
                        const SizedBox(),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: const Color(0xFF222222),
                child: Icon(icon, color: const Color(0xFF4CFF00))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(value,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions(String uid) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final sesionesQuery = FirebaseFirestore.instance
        .collection('sesiones')
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(3);

    return StreamBuilder<QuerySnapshot>(
      stream: sesionesQuery.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator()));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Aún no hay sesiones registradas.'));
        }

        return Column(
          children: [
            ...docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              final rawDate = data['date'];
              DateTime date;
              if (rawDate is Timestamp) {
                date = rawDate.toDate();
              } else if (rawDate is DateTime) {
                date = rawDate;
              } else if (rawDate is String) {
                date = DateTime.tryParse(rawDate) ?? DateTime.now();
              } else {
                date = DateTime.now();
              }
              final ejercicios = (data['exercises'] as List<dynamic>?) ?? [];
              final duracion = data['duracionMin'] ?? data['durationMin'] ?? 0;
              final completado = ejercicios.isNotEmpty &&
                  ejercicios.every((e) => e is Map && (e['completed'] == true));

              return Card(
                child: ExpansionTile(
                  title: Text(fmt.format(date)),
                  subtitle: Text(
                      'Duración: ${duracion} min • ${ejercicios.length} ejercicios'),
                  trailing: Icon(completado ? Icons.check_circle : Icons.error,
                      color: completado ? Colors.green : Colors.red),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: ejercicios.map<Widget>((e) {
                              final nombre = (e is Map)
                                  ? (e['nombre'] ?? 'Ejercicio')
                                  : 'Ejercicio';
                              final repsReal = (e is Map)
                                  ? (e['repsRealizadas']?.toString() ?? '-')
                                  : '-';
                              final peso = (e is Map)
                                  ? (e['peso_usado'] ??
                                      e['pesoPlanificado'] ??
                                      '-')
                                  : '-';
                              return Chip(
                                  label: Text(
                                      '$nombre • ${repsReal} reps • ${peso} kg'));
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const HistorialScreen())),
                                child: const Text('Ver historial completo'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildRecentAchievements(String uid) {
    final repo = GamificationRepository(
        FirebaseFirestore.instance, FirebaseAuth.instance);
    final service = GamificationService(repo);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return StreamBuilder<List<Logro>>(
      stream: repo.logrosRecientesStream(uid, limit: 3),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator()));
        }
        final logros = snap.data ?? [];
        if (logros.isEmpty) {
          return const Text('Aún no tienes logros.');
        }
        return Column(
          children: logros.map((l) {
            final otorgado = l.otorgadoEn;
            final subtitleText =
                l.descripcion + '\n${dateFmt.format(otorgado)}';
            return Card(
              child: ListTile(
                leading: l.badge != null
                    ? SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(l.badge!, fit: BoxFit.contain))
                    : const Icon(Icons.emoji_events, color: Color(0xFF4CFF00)),
                title: Text(l.nombre),
                subtitle: Text(subtitleText),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('+${l.puntosOtorgados}',
                        style: const TextStyle(
                            color: Color(0xFF4CFF00),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AchievementsScreen(
                          uid: uid, repo: repo, service: service),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Si stats ya contiene sesionesMes/minutosMes devuelve inmediatamente,
  /// si no, consulta las sesiones del último mes y suma duración y cuenta.
  // ignore: unused_element
  Future<Map<String, int>> _computeMonthlyStatsIfNeeded(
      String? uid, Map<String, dynamic> stats) async {
    if (uid == null) return {'sesionesMes': 0, 'minutosMes': 0};
    if (stats.containsKey('sesionesMes') && stats.containsKey('minutosMes')) {
      return {
        'sesionesMes': (stats['sesionesMes'] is num)
            ? (stats['sesionesMes'] as num).toInt()
            : 0,
        'minutosMes': (stats['minutosMes'] is num)
            ? (stats['minutosMes'] as num).toInt()
            : 0,
      };
    }
    final desde = DateTime.now().subtract(const Duration(days: 30));
    final q = FirebaseFirestore.instance
        .collection('sesiones')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(desde));
    final snap = await q.get();
    int sesiones = 0;
    int minutos = 0;
    for (final d in snap.docs) {
      final data = d.data();
      sesiones += 1;
      final rawDur = data['duracionMin'] ?? data['durationMin'] ?? 0;
      if (rawDur is num) {
        minutos += rawDur.toInt();
      } else if (rawDur is String) {
        minutos += int.tryParse(rawDur) ?? 0;
      }
    }
    return {'sesionesMes': sesiones, 'minutosMes': minutos};
  }
}
