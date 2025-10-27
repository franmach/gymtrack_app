import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          const Text('Error al cargar perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(desde));

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
                                  return const AssetImage('assets/images/profile_placeholder.png') as ImageProvider;
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
                                return const AssetImage('assets/images/profile_placeholder.png') as ImageProvider;
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
                              child: SizedBox(
                                width: double.infinity,
                                child: GridView.count(
                                  shrinkWrap: true,
                                  crossAxisCount: 2, // 2 columnas -> 2 arriba y 2 abajo
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 4, // ajustar la altura de los botones
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => setState(
                                          () => modoEdicion = !modoEdicion),
                                      icon: Icon(
                                          modoEdicion ? Icons.check : Icons.edit),
                                      label:
                                          Text(modoEdicion ? 'Guardar' : 'Editar'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const HistorialScreen()));
                                      },
                                      icon: const Icon(Icons.history),
                                      label: const Text('Historial'),
                                    ),
                                    OutlinedButton.icon(
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
                                        final service = GamificationService(repo);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AchievementsScreen(
                                                uid: uid,
                                                repo: repo,
                                                service: service),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.emoji_events),
                                      label: const Text('Logros'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MisRutinasScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.list),
                                      label: const Text('Mis Rutinas'),
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
                                  leading: const Icon(Icons.align_horizontal_left),
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
                                    decoration: const InputDecoration(
                                        labelText: 'Peso (kg)')),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: alturaController,
                                    decoration: const InputDecoration(
                                        labelText: 'Altura (cm)')),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: disponibilidadController,
                                    decoration: const InputDecoration(
                                        labelText: 'Disponibilidad semanal')),
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
                          int sesiones = (stats['sesionesMes'] is num) ? (stats['sesionesMes'] as num).toInt() : 0;
                          int minutos = (stats['minutosMes'] is num) ? (stats['minutosMes'] as num).toInt() : 0;

                          if (sSnap.hasData) {
                            final docs = sSnap.data!.docs;
                            sesiones = docs.length;
                            minutos = 0;
                            for (final d in docs) {
                              final data = d.data() as Map<String, dynamic>;
                              final rawDur = data['duracionMin'] ?? data['durationMin'] ?? 0;
                              if (rawDur is num) minutos += rawDur.toInt();
                              else if (rawDur is String) minutos += int.tryParse(rawDur) ?? 0;
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
                                          stats['rachaActual']?.toString() ?? '0',
                                          Icons.local_fire_department)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: _kpiCard('Sesiones (mes)', sesiones.toString(), Icons.calendar_month)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _kpiCard('Minutos (mes)', minutos.toString(), Icons.timer),
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
            final subtitleText = l.descripcion + '\n${dateFmt.format(otorgado)}';
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
