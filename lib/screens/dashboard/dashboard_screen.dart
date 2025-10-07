import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/models/educational_advice.dart';
import 'package:gymtrack_app/screens/contenido_edu/educational_advice_screen.dart';
import 'package:gymtrack_app/screens/historial/historial_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/main.dart';
import 'package:gymtrack_app/screens/notificacion/notificaciones_screen.dart';
import 'package:gymtrack_app/screens/perfil/completar_perfil.dart';
import 'package:gymtrack_app/screens/perfil/perfil_screen.dart';
import 'package:gymtrack_app/screens/perfil/perfil_wizard_screen.dart';
import 'package:gymtrack_app/services/firestore_routine_service.dart';
import 'package:gymtrack_app/screens/session/day_selection_screen.dart';
import 'package:gymtrack_app/screens/session/timer_screen.dart';
import 'package:gymtrack_app/screens/admin/gimnasio_screen.dart';
import 'package:gymtrack_app/screens/progreso/registroProgreso_screen.dart';
import 'package:gymtrack_app/screens/progreso/visualizarProgreso_screen.dart';
import 'package:gymtrack_app/models/usuario.dart';
import 'package:gymtrack_app/services/ajuste_rutina_service.dart';
import 'package:gymtrack_app/services/ai_service.dart';
import 'package:gymtrack_app/services/user_repository.dart';
import 'dart:math';
import 'dart:async';
import 'package:gymtrack_app/services/advice_service.dart';
import 'package:intl/intl.dart';
import 'package:gymtrack_app/gymtrack_theme.dart';

/// DashboardScreen: Pantalla principal tras iniciar sesión
typedef DocSnapshot = DocumentSnapshot<Map<String, dynamic>>;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _userRepo = UserRepository();
  final AdviceService _adviceService = AdviceService();
  bool _profileAutoUpgraded = false;

  bool _heuristicComplete(Map<String, dynamic> u) {
    bool hasBasics = (u['nombre'] ?? '').toString().isNotEmpty &&
        (u['apellido'] ?? '').toString().isNotEmpty &&
        (u['objetivo'] ?? '').toString().isNotEmpty &&
        (u['nivelExperiencia'] ?? '').toString().isNotEmpty;
    bool hasMetrics = (u['peso'] ?? 0) is num &&
        (u['peso'] ?? 0) > 0 &&
        (u['altura'] ?? 0) is num &&
        (u['altura'] ?? 0) > 0 &&
        (u['disponibilidadSemanal'] ?? 0) is num &&
        (u['disponibilidadSemanal'] ?? 0) > 0;
    return hasBasics && hasMetrics;
  }

  @override
  void initState() {
    super.initState();
    _ajustarRutinaSiCorresponde();
  }

  Future<void> _ajustarRutinaSiCorresponde() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('usuarios').doc(uid).get();
    if (!userDoc.exists) return;
    final usuario = Usuario.fromMap(userDoc.data()!, uid);
    final ajusteService = AjusteRutinaService(
      firestore: firestore,
      aiService: AiService(),
    );
    try {
      await ajusteService.ajustarRutinaMensual(usuario);
    } catch (e, stack) {
      debugPrint('❌ Error en ajuste automático: $e');
      debugPrint('$stack');
    }
  }

  void _onMenuSelect(String value) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (value == 'profile') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
    } else if (value == 'notifications') {
      if (uid == null) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ConfigNotificacionesScreen(usuarioId: uid)));
    } else if (value == 'settings') {
      //Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null)
      return const Scaffold(
          body: Center(child: Text('Usuario no autenticado')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenuSelect,
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'profile', child: Text('Perfil')),
              const PopupMenuItem(
                  value: 'notifications', child: Text('Notificaciones')),
              const PopupMenuItem(
                  value: 'settings', child: Text('Configuración')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userRepo.streamUserDoc(uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (userSnap.hasError) {
              return Text('Error usuario: ${userSnap.error}');
            }
            final usuarioDoc = userSnap.data?.data() ?? {};
            final bool perfilCompletoFlag =
                (usuarioDoc['perfilCompleto'] ?? false) == true;
            final bool perfilCompleto =
                perfilCompletoFlag || _heuristicComplete(usuarioDoc);

            // Si la heurística dice que está completo pero el flag no está marcado, actualizamos una sola vez
            if (perfilCompleto &&
                !perfilCompletoFlag &&
                !_profileAutoUpgraded) {
              _profileAutoUpgraded = true;
              FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .update({'perfilCompleto': true}).catchError((_) {});
            }

            final displayName =
                (usuarioDoc['nombre'] ?? usuarioDoc['displayName'])
                        ?.toString() ??
                    FirebaseAuth.instance.currentUser?.displayName ??
                    'Usuario';
            final streakRaw = usuarioDoc['rachaActual'] ??
                usuarioDoc['racha_record'] ??
                usuarioDoc['racha'] ??
                usuarioDoc['streak'] ??
                0;
            final int streak = (streakRaw is num)
                ? streakRaw.toInt()
                : int.tryParse('$streakRaw') ?? 0;

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
              stream: _userRepo.streamRutinaActual(uid),
              builder: (context, rutSnap) {
                if (rutSnap.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final rutinasDoc = rutSnap.data?.data() ?? {};

                // Lógica próximo entrenamiento (sin cambios)
                String nextName = 'Sin rutina';
                String nextWhen = '—';
                final rutinaRaw = rutinasDoc['rutina'];
                if (rutinaRaw is List && rutinaRaw.isNotEmpty) {
                  final Map<String, int> dayMap = {
                    'lunes': 1,
                    'martes': 2,
                    'miércoles': 3,
                    'miercoles': 3,
                    'jueves': 4,
                    'viernes': 5,
                    'sábado': 6,
                    'sabado': 6,
                    'domingo': 7
                  };
                  final today = DateTime.now().weekday;
                  int bestDelta = 999;
                  Map<String, dynamic>? bestEntry;
                  for (final e in rutinaRaw) {
                    if (e is Map<String, dynamic>) {
                      final rawDay = (e['dia'] ?? e['day'] ?? e['nombreDia'])
                              ?.toString() ??
                          '';
                      final dayKey = rawDay.toLowerCase().trim();
                      final target = dayMap[dayKey];
                      if (target == null) continue;
                      int delta = (target - today + 7) % 7;
                      if (delta == 0) delta = 7;
                      if (delta < bestDelta) {
                        bestDelta = delta;
                        bestEntry = e;
                      }
                    }
                  }
                  final chosen = bestEntry ??
                      (rutinaRaw.first is Map
                          ? rutinaRaw.first as Map<String, dynamic>
                          : null);
                  if (chosen != null) {
                    final diaLabel =
                        (chosen['dia'] ?? chosen['day'])?.toString() ?? '';
                    final ejercicios = chosen['ejercicios'];
                    final int exercisesCount =
                        (ejercicios is List) ? ejercicios.length : 0;
                    nextName = diaLabel.isNotEmpty
                        ? '$diaLabel (${exercisesCount} ejercicios)'
                        : 'Rutina';
                    nextWhen = (bestDelta == 0)
                        ? 'Hoy'
                        : (diaLabel.isNotEmpty ? diaLabel : 'Próxima sesión');
                    if (bestDelta == 7) {
                      nextWhen = 'Próxima semana • $diaLabel';
                    } else if (bestDelta > 0 && bestDelta < 7)
                      nextWhen = diaLabel;
                  }
                }

                if (!perfilCompleto) {
                  // Vista SIN scroll que ocupa todo el alto disponible
                  return _buildIncompleteDashboard(
                    displayName: displayName,
                    uid: uid,
                  );
                }
                // Vista con perfil completo (puede scrollear si hace falta)
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            child: Text(
                              displayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hola, $displayName',
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('A por tu objetivo de hoy',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text('$streak'),
                            avatar: const Icon(Icons.whatshot_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Próximo entrenamiento',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('$nextName • $nextWhen'),
                              const SizedBox(height: 12),
                              StreamBuilder<int>(
                                stream: _userRepo
                                    .streamAsistenciasCountLastNDays(uid, 30),
                                builder: (context, asistSnap) {
                                  final int asistenciasLast30 =
                                      asistSnap.data ?? 0;
                                  final diasPorSemanaRaw =
                                      rutinasDoc['dias_por_semana'] ??
                                          rutinasDoc['diasPorSemana'] ??
                                          rutinasDoc['dias_porsemana'] ??
                                          rutinasDoc['dias'] ??
                                          0;
                                  final int diasPorSemana =
                                      (diasPorSemanaRaw is num)
                                          ? diasPorSemanaRaw.toInt()
                                          : int.tryParse(
                                                  '$diasPorSemanaRaw') ??
                                              0;
                                  double progress = 0.0;
                                  if (diasPorSemana > 0) {
                                    final double expectedSessions =
                                        diasPorSemana * (30 / 7.0);
                                    progress =
                                        (asistenciasLast30 / expectedSessions)
                                            .clamp(0.0, 1.0);
                                  }
                                  final percent = (progress * 100).round();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      LinearProgressIndicator(value: progress),
                                      const SizedBox(height: 8),
                                      Text(
                                          '$percent% completado • $asistenciasLast30 sesiones (30 días)',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DaySelectionScreen(
                                        service: FirestoreRoutineService(),
                                        userId: uid,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Ver rutina'),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildButtons(true, uid),
                      const SizedBox(height: 20),
                      EducationCard(uid: uid, adviceService: _adviceService),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtons(bool perfilCompleto, String uid) {
    if (!perfilCompleto) {
      final carouselHeight = MediaQuery.of(context).size.height * 0.45;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 40),
              label: const Text(
                'Completar perfil',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PerfilWizardScreen(uid: uid),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _BenefitCarousel(
            height: carouselHeight,
            items: const [
              'Rutinas personalizadas según tus datos',
              'Gráficos claros de tu progreso',
              'Ajustes automáticos con IA',
              'Historial completo de entrenamientos',
              'Rachas y motivación gamificada',
              'Próximos: desafíos y ranking',
            ],
          ),
        ],
      );
    }

    // Vista cuando el perfil YA está completo (grid original mejorado)
    final buttons = <Widget>[
      ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DaySelectionScreen(
                service: FirestoreRoutineService(),
                userId: uid,
              ),
            ),
          );
        },
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Ajuste AI'),
        onPressed: () async {
          final firestore = FirebaseFirestore.instance;
          final current = FirebaseAuth.instance.currentUser?.uid;
          if (current == null) return;
          final userDoc =
              await firestore.collection('usuarios').doc(current).get();
          if (!userDoc.exists) return;
          final usuario = Usuario.fromMap(userDoc.data()!, current);
          final ajusteService =
              AjusteRutinaService(firestore: firestore, aiService: AiService());
          try {
            await ajusteService.ajustarRutinaMensual(usuario);
          } catch (e) {
            debugPrint('Error ajuste: $e');
          }
        },
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.history),
        label: const Text('Historial'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HistorialScreen()),
          );
        },
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.timer),
        label: const Text('Temporizador'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TimerScreen()),
          );
        },
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 3.0,
      children: buttons,
    );
  }

  Widget _buildIncompleteDashboard({
    required String displayName,
    required String uid,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16,16,16,8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, $displayName',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Completa tu perfil para crear tu plan de entrenamiento personalizado.',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Solo te tomará un minuto.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 42),
                label: const Text(
                  'Completar perfil',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PerfilWizardScreen(uid: uid),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // El carrusel ocupa todo el resto sin overflow
            Expanded(
              child: _BenefitCarousel(
                items: const [
                  'Rutinas personalizadas según tus datos',
                  'Gráficos claros de tu progreso',
                  'Ajustes automáticos con IA',
                  'Historial completo de entrenamientos',
                  'Rachas y motivación gamificada',
                  'Próximos: desafíos y ranking',
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EducationCard extends StatefulWidget {
  final String uid;
  final AdviceService adviceService;
  const EducationCard(
      {Key? key, required this.uid, required this.adviceService})
      : super(key: key);

  @override
  State<EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<EducationCard> {
  late Future<EducationalAdvice?> _futureAdvice;

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  void _loadAdvice({bool preferLatest = false}) {
    _futureAdvice = _fetchAdvice(preferLatest: preferLatest);
  }

  Future<EducationalAdvice?> _fetchAdvice({bool preferLatest = false}) async {
    try {
      final advices = await widget.adviceService.getUserAdvices(widget.uid);
      if (advices.isEmpty) return null;
      if (preferLatest) return advices.first;
      final rnd = Random(DateTime.now().millisecondsSinceEpoch);
      return advices[rnd.nextInt(advices.length)];
    } catch (e) {
      debugPrint('Error fetching advices: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        Theme.of(context).textTheme.labelLarge?.copyWith(color: verdeFluor);
    final bodyStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: blanco);
    final metaStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: grisClaro);

    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Contenido educativo', style: titleStyle),
            const SizedBox(height: 8),
            FutureBuilder<EducationalAdvice?>(
              future: _futureAdvice,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Text('Error cargando consejo: ${snap.error}',
                      style: metaStyle);
                }
                final advice = snap.data;
                if (advice == null) {
                  return Text('No hay consejos disponibles por ahora.',
                      style: bodyStyle);
                }
                final fechaStr = DateFormat('dd/MM/yyyy').format(advice.fecha);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(advice.tipo.toUpperCase(),
                        style: titleStyle?.copyWith(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(advice.mensaje, style: bodyStyle),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fechaStr, style: metaStyle),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: advice.fuente == 'ai'
                                    ? verdeFluor.withOpacity(0.12)
                                    : Colors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                  advice.fuente == 'ai'
                                      ? 'Generado por IA'
                                      : 'Manual',
                                  style: metaStyle),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: blanco),
                              tooltip: 'Otro consejo',
                              onPressed: () {
                                // sólo recarga esta card
                                setState(() => _loadAdvice());
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EducationalAdviceScreen()));
              },
              child: const Text('Abrir contenido educativo'),
            )
          ],
        ),
      ),
    );
  }
}

// Carrusel de beneficios (solo se usa con perfil incompleto)
class _BenefitCarousel extends StatefulWidget {
  final List<String> items;
  final double? height; // opcional (si se pasa, fuerza alto)
  const _BenefitCarousel({super.key, required this.items, this.height});

  @override
  State<_BenefitCarousel> createState() => _BenefitCarouselState();
}

class _BenefitCarouselState extends State<_BenefitCarousel> {
  final _controller = PageController(viewportFraction: 0.9);
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _index = (_index + 1) % widget.items.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotBase = Colors.white;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Alto disponible (resta espacio para dots)
        final total = widget.height ?? constraints.maxHeight;
        final pagerHeight = (total - 34).clamp(140.0, total);
        return Column(
          children: [
            SizedBox(
              height: pagerHeight,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: widget.items.length,
                itemBuilder: (ctx, i) {
                  final active = i == _index;
                  return AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: active ? 1.0 : 0.94,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: active ? 1 : 0.6,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.35),
                              blurRadius: 10,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.items[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 10,
                  width: active ? 28 : 10,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : dotBase.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.7),
                              blurRadius: 6,
                              spreadRadius: 0.5,
                            )
                          ]
                        : [],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
