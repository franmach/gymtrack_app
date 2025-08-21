import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gamification.dart';
import '../models/logro.dart';
import '../models/usuario.dart';
import 'gamification_repository.dart';

class GamificationService {
  final GamificationRepository repo;

  GamificationService(this.repo);




Future<void> onSesionCompletada(String uid, DateTime ahoraLocal, {required String sesionId}) async {
    await repo.initStatsIfMissing(uid);

    // Idempotencia: si ya existe asistencia de hoy, salir
    if (await repo.existeAsistenciaDelDia(uid, ahoraLocal)) return;

    // Crear asistencia del día
    await repo.crearAsistenciaDelDia(uid, ahoraLocal);

    // Leer stats actuales
    final statsSnap = await repo.refUsuarios.doc(uid).get();
    final stats = statsSnap.data();
    final rachaResult = calcularRacha(
      ultimaAsistencia: stats?.ultimaAsistencia,
      hoy: ahoraLocal,
      rachaActual: stats?.rachaActual ?? 0,
    );
    final nuevaRacha = rachaResult.nuevaRacha;

    // Actualizar racha, récord y ultimaAsistencia
    await repo.actualizarRachaYRecord(
      uid,
      nuevaRacha: nuevaRacha,
      hoy: ahoraLocal,
      actualizarUltima: true,
    );

    // Sumar puntos diarios
    await repo.incrementarPuntos(uid, 10);

    // Verificar hitos de racha
    if ([7, 14, 30].contains(nuevaRacha)) {
      final badge = nuevaRacha == 7
          ? 'Bronce'
          : nuevaRacha == 14
              ? 'Plata'
              : 'Imparable';
      final puntosBadge = nuevaRacha == 7
          ? 50
          : nuevaRacha == 14
              ? 100
              : 200;
      final logroId = 'racha:$nuevaRacha';
      final logro = Logro(
        id: logroId,
        nombre: 'Racha $badge',
        descripcion: '¡Has alcanzado una racha de $nuevaRacha días!',
        puntosOtorgados: puntosBadge,
        tipo: 'racha',
        periodo: null,
        otorgadoEn: ahoraLocal,
      );
      await repo.otorgarLogro(uid, logro);
      await repo.incrementarPuntos(uid, puntosBadge);
    }

    // Verificar metas semanales/mensuales
    final asistenciasSemana = await contarAsistenciasSemana(uid, ahoraLocal);
    final asistenciasMes = await contarAsistenciasMes(uid, ahoraLocal);
    final objetivoSemanal = await obtenerObjetivoSemanal(uid);

    // Semanal
    final semanaKey = keySemana(ahoraLocal);
    if (asistenciasSemana >= objetivoSemanal) {
      final logroSemanalId = 'semanal:$semanaKey';
      final logroSemanal = Logro(
        id: logroSemanalId,
        nombre: 'Semana cumplida',
        descripcion: '¡Cumpliste tu meta semanal!',
        puntosOtorgados: 100,
        tipo: 'semanal',
        periodo: semanaKey,
        otorgadoEn: ahoraLocal,
      );
      await repo.otorgarLogro(uid, logroSemanal);
      await repo.incrementarPuntos(uid, 100);
    }

    // Mensual
    final mesKey = keyMes(ahoraLocal);
    if (asistenciasMes >= objetivoSemanal * 4) {
      final logroMensualId = 'mensual:$mesKey';
      final logroMensual = Logro(
        id: logroMensualId,
        nombre: 'Mes cumplido',
        descripcion: '¡Cumpliste tu meta mensual!',
        puntosOtorgados: 400,
        tipo: 'mensual',
        periodo: mesKey,
        otorgadoEn: ahoraLocal,
      );
      await repo.otorgarLogro(uid, logroMensual);
      await repo.incrementarPuntos(uid, 400);
    }

    // Volumen total levantado
final volumenTotal = await calcularVolumenTotal(uid);
for (final meta in [10000, 50000, 100000]) {
  final logroId = 'volumen:$meta';
  if (volumenTotal >= meta && !(await repo.existeLogro(uid, logroId))) {
    await repo.otorgarLogro(uid, Logro(
      id: logroId,
      nombre: 'Volumen $meta kg',
      descripcion: '¡Has levantado más de $meta kg en total!',
      puntosOtorgados: meta ~/ 100,
      tipo: 'volumen',
      periodo: null,
      otorgadoEn: ahoraLocal,
    ));
  }
}

// Día récord de volumen
final maxVol = await calcularVolumenMaxSesion(uid);
final logroVolDiaId = 'volumenDia:$maxVol';
if (!(await repo.existeLogro(uid, logroVolDiaId))) {
  await repo.otorgarLogro(uid, Logro(
    id: logroVolDiaId,
    nombre: 'Día récord de volumen',
    descripcion: '¡Has logrado $maxVol kg en una sola sesión!',
    puntosOtorgados: 50,
    tipo: 'volumenDia',
    periodo: keyDia(ahoraLocal),
    otorgadoEn: ahoraLocal,
  ));
}

// Maestro de repeticiones
final totalReps = await calcularRepeticionesTotales(uid);
for (final meta in [5000, 10000, 50000]) {
  final logroId = 'reps:$meta';
  if (totalReps >= meta && !(await repo.existeLogro(uid, logroId))) {
    await repo.otorgarLogro(uid, Logro(
      id: logroId,
      nombre: 'Maestro de repeticiones $meta',
      descripcion: '¡Has realizado más de $meta repeticiones!',
      puntosOtorgados: meta ~/ 100,
      tipo: 'repeticiones',
      periodo: null,
      otorgadoEn: ahoraLocal,
    ));
  }
}

// Sesión con más repeticiones
final maxReps = await calcularRepsMaxSesion(uid);
final logroRepsDiaId = 'repsDia:$maxReps';
if (!(await repo.existeLogro(uid, logroRepsDiaId))) {
  await repo.otorgarLogro(uid, Logro(
    id: logroRepsDiaId,
    nombre: 'Sesión récord de repeticiones',
    descripcion: '¡Has logrado $maxReps repeticiones en una sesión!',
    puntosOtorgados: 50,
    tipo: 'repsDia',
    periodo: keyDia(ahoraLocal),
    otorgadoEn: ahoraLocal,
  ));
}

// Constancia semanal (ejemplo: 4 días por semana durante 3 semanas seguidas)
final semanasConstantes = await contarSemanasConstantes(uid, 4, 3);
if (semanasConstantes >= 3 && !(await repo.existeLogro(uid, 'constancia:3'))) {
  await repo.otorgarLogro(uid, Logro(
    id: 'constancia:3',
    nombre: 'Constancia semanal',
    descripcion: 'Entrenaste al menos 4 días por semana durante 3 semanas seguidas.',
    puntosOtorgados: 100,
    tipo: 'frecuencia',
    periodo: null,
    otorgadoEn: ahoraLocal,
  ));
}

// Mes sin faltar
final mesActual = DateTime(ahoraLocal.year, ahoraLocal.month, 1);
if (await mesSinFaltar(uid, mesActual) && !(await repo.existeLogro(uid, 'mesSinFaltar:${keyMes(ahoraLocal)}'))) {
  await repo.otorgarLogro(uid, Logro(
    id: 'mesSinFaltar:${keyMes(ahoraLocal)}',
    nombre: 'Mes sin faltar',
    descripcion: 'Entrenaste todos los días del mes.',
    puntosOtorgados: 200,
    tipo: 'frecuencia',
    periodo: keyMes(ahoraLocal),
    otorgadoEn: ahoraLocal,
  ));
}

// Especialista en ejercicio (ejemplo: sentadillas)
final sentadillas = await contarEjercicio(uid, 'Sentadillas');
if (sentadillas >= 1000 && !(await repo.existeLogro(uid, 'especialista:sentadillas'))) {
  await repo.otorgarLogro(uid, Logro(
    id: 'especialista:sentadillas',
    nombre: 'Especialista en sentadillas',
    descripcion: '¡Has realizado más de 1000 sentadillas!',
    puntosOtorgados: 100,
    tipo: 'ejercicio',
    periodo: null,
    otorgadoEn: ahoraLocal,
  ));
}

// PR alcanzado (ejemplo: sentadillas)
final prSentadillas = await prEjercicio(uid, 'Sentadillas');
if (prSentadillas >= 100 && !(await repo.existeLogro(uid, 'pr:sentadillas'))) {
  await repo.otorgarLogro(uid, Logro(
    id: 'pr:sentadillas',
    nombre: 'PR en sentadillas',
    descripcion: '¡Nuevo récord de peso en sentadillas: $prSentadillas kg!',
    puntosOtorgados: 100,
    tipo: 'pr',
    periodo: null,
    otorgadoEn: ahoraLocal,
  ));
}

// Rutina variada
if (await rutinaVariada(uid, ahoraLocal) && !(await repo.existeLogro(uid, 'rutinaVariada:${keySemana(ahoraLocal)}'))) {
  await repo.otorgarLogro(uid, Logro(
    id: 'rutinaVariada:${keySemana(ahoraLocal)}',
    nombre: 'Rutina variada',
    descripcion: 'Entrenaste todos los grupos musculares principales esta semana.',
    puntosOtorgados: 100,
    tipo: 'variedad',
    periodo: keySemana(ahoraLocal),
    otorgadoEn: ahoraLocal,
  ));
}

// Explorador de ejercicios
final ejerciciosDistintos = await ejerciciosDiferentes(uid);
for (final meta in [10, 20, 50]) {
  final logroId = 'explorador:$meta';
  if (ejerciciosDistintos >= meta && !(await repo.existeLogro(uid, logroId))) {
    await repo.otorgarLogro(uid, Logro(
      id: logroId,
      nombre: 'Explorador de ejercicios $meta',
      descripcion: '¡Has probado más de $meta ejercicios diferentes!',
      puntosOtorgados: meta * 2,
      tipo: 'variedad',
      periodo: null,
      otorgadoEn: ahoraLocal,
    ));
  }
}

// 100% cumplido (para la sesión actual)
if (await sesionCumplida(sesionId) && !(await repo.existeLogro(uid, 'cumplido:$sesionId'))) {
  await repo.otorgarLogro(uid, Logro(
    id: 'cumplido:$sesionId',
    nombre: '100% cumplido',
    descripcion: 'Completaste todas las repeticiones y ejercicios planificados en esta sesión.',
    puntosOtorgados: 50,
    tipo: 'cumplimiento',
    periodo: keyDia(ahoraLocal),
    otorgadoEn: ahoraLocal,
  ));
}

// Semana perfecta
if (await semanaPerfecta(uid, ahoraLocal) && !(await repo.existeLogro(uid, 'semanaPerfecta:${keySemana(ahoraLocal)}'))) {
  await repo.otorgarLogro(uid, Logro(
    id: 'semanaPerfecta:${keySemana(ahoraLocal)}',
    nombre: 'Semana perfecta',
    descripcion: 'Cumpliste el 100% de las sesiones y ejercicios planificados esta semana.',
    puntosOtorgados: 150,
    tipo: 'cumplimiento',
    periodo: keySemana(ahoraLocal),
    otorgadoEn: ahoraLocal,
  ));
}
  }

  Future<int> contarAsistenciasSemana(String uid, DateTime hoy) async {
    final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
    final finSemana = inicioSemana.add(const Duration(days: 6));
    final snap = await repo.asistenciasRef(uid)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemana))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(finSemana))
        .get();
    return snap.size;
  }

  Future<int> contarAsistenciasMes(String uid, DateTime hoy) async {
    final inicioMes = DateTime(hoy.year, hoy.month, 1);
    final finMes = DateTime(hoy.year, hoy.month + 1, 0);
    final snap = await repo.asistenciasRef(uid)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(finMes))
        .get();
    return snap.size;
  }

  Future<int> obtenerObjetivoSemanal(String uid) async {
  final doc = await repo.firestore.collection('usuarios').doc(uid).get();
  final data = doc.data();
  return data?['disponibilidadSemanal'] ?? 3;
}


// Volumen total levantado en todas las sesiones
Future<int> calcularVolumenTotal(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('sesiones')
      .where('uid', isEqualTo: uid)
      .get();
  int total = 0;
  for (var doc in snap.docs) {
    final ejercicios = doc['exercises'] as List<dynamic>? ?? [];
    for (var e in ejercicios) {
      final peso = (e['peso_usado'] ?? e['pesoPlanificado']) ?? 0;
      final reps = e['repsRealizadas'] ?? 0;
      total += (peso as num).toInt() * (reps as num).toInt();
    }
  }
  return total;
}

// Volumen máximo en una sola sesión
Future<int> calcularVolumenMaxSesion(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('sesiones')
      .where('uid', isEqualTo: uid)
      .get();
  int maxVol = 0;
  for (var doc in snap.docs) {
    int vol = 0;
    final ejercicios = doc['exercises'] as List<dynamic>? ?? [];
    for (var e in ejercicios) {
      final peso = (e['peso_usado'] ?? e['pesoPlanificado']) ?? 0;
      final reps = e['repsRealizadas'] ?? 0;
      vol += (peso as num).toInt() * (reps as num).toInt();
    }
    if (vol > maxVol) maxVol = vol;
  }
  return maxVol;
}

// Repeticiones totales en todas las sesiones
Future<int> calcularRepeticionesTotales(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('sesiones')
      .where('uid', isEqualTo: uid)
      .get();
  int total = 0;
  for (var doc in snap.docs) {
    final ejercicios = doc['exercises'] as List<dynamic>? ?? [];
    for (var e in ejercicios) {
      total += (e['repsRealizadas'] ?? 0) as int;
    }
  }
  return total;
}

// Máximo de repeticiones en una sesión
Future<int> calcularRepsMaxSesion(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('sesiones')
      .where('uid', isEqualTo: uid)
      .get();
  int maxReps = 0;
  for (var doc in snap.docs) {
    int reps = 0;
    final ejercicios = doc['exercises'] as List<dynamic>? ?? [];
    for (var e in ejercicios) {
      reps += (e['repsRealizadas'] ?? 0) as int;
    }
    if (reps > maxReps) maxReps = reps;
  }
  return maxReps;
}

// Constancia semanal: entrenar al menos X días cada semana durante N semanas seguidas
Future<int> contarSemanasConstantes(String uid, int diasPorSemana, int semanasMin) async {
  // Agrupa asistencias por semana y cuenta las que cumplen el mínimo
  final asistenciasSnap = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .collection('asistencias')
      .get();
  Map<String, int> semanas = {};
  for (var doc in asistenciasSnap.docs) {
    final fecha = (doc['fecha'] as Timestamp).toDate();
    final key = keySemana(fecha);
    semanas[key] = (semanas[key] ?? 0) + 1;
  }
  int racha = 0;
  for (var semana in semanas.values) {
    if (semana >= diasPorSemana) {
      racha++;
      if (racha >= semanasMin) return racha;
    } else {
      racha = 0;
    }
  }
  return racha;
}

// Mes sin faltar: entrenar todos los días de un mes
Future<bool> mesSinFaltar(String uid, DateTime mes) async {
  final inicio = DateTime(mes.year, mes.month, 1);
  final fin = DateTime(mes.year, mes.month + 1, 0);
  final snap = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .collection('asistencias')
      .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
      .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(fin))
      .get();
  return snap.size == fin.day;
}

// Especialista en ejercicio: realizar cierto ejercicio más de N veces
Future<int> contarEjercicio(String uid, String ejercicio) async {
  final snap = await FirebaseFirestore.instance
      .collection('sesiones')
      .where('uid', isEqualTo: uid)
      .get();
  int total = 0;
  for (var doc in snap.docs) {
    final ejercicios = doc['exercises'] as List<dynamic>? ?? [];
    for (var e in ejercicios) {
      if ((e['nombre'] ?? '') == ejercicio) {
        total += (e['repsRealizadas'] ?? 0) as int;
      }
    }
  }
  return total;
}

// PR alcanzado: récord de peso en un ejercicio
Future<double> prEjercicio(String uid, String ejercicio) async {
  final snap = await FirebaseFirestore.instance
      .collection('sesiones')
      .where('uid', isEqualTo: uid)
      .get();
  double pr = 0;
  for (var doc in snap.docs) {
    final ejercicios = doc['exercises'] as List<dynamic>? ?? [];
    for (var e in ejercicios) {
      if ((e['nombre'] ?? '') == ejercicio) {
        final peso = (e['peso_usado'] ?? e['pesoPlanificado'])?.toDouble() ?? 0;
        if (peso > pr) pr = peso;
      }
    }
  }
  return pr;
}

// Rutina variada: entrenar todos los grupos musculares principales en una semana
Future<bool> rutinaVariada(String uid, DateTime semana) async {
  final inicio = semana.subtract(Duration(days: semana.weekday - 1));
  final fin = inicio.add(const Duration(days: 6));
  final snap = await FirebaseFirestore.instance
      .collection('sesiones')
      .where('uid', isEqualTo: uid)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(fin))
      .get();
  final grupos = <String>{};
  for (var doc in snap.docs) {
    final ejercicios = doc['exercises'] as List<dynamic>? ?? [];
    for (var e in ejercicios) {
      if (e['grupoMuscular'] != null) grupos.add(e['grupoMuscular']);
    }
  }
  // Ajusta la lista de grupos según tu modelo
  const gruposPrincipales = ['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos', 'Abdomen'];
  return gruposPrincipales.every((g) => grupos.contains(g));
}

// Explorador de ejercicios: probar más de X ejercicios diferentes
Future<int> ejerciciosDiferentes(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('sesiones')
      .where('uid', isEqualTo: uid)
      .get();
  final ejercicios = <String>{};
  for (var doc in snap.docs) {
    final lista = doc['exercises'] as List<dynamic>? ?? [];
    for (var e in lista) {
      ejercicios.add(e['nombre'] ?? '');
    }
  }
  return ejercicios.length;
}

// 100% cumplido: completar todas las repeticiones y ejercicios planificados en una sesión
Future<bool> sesionCumplida(String sesionId) async {
  final doc = await FirebaseFirestore.instance.collection('sesiones').doc(sesionId).get();
  final ejercicios = doc['exercises'] as List<dynamic>? ?? [];
  for (var e in ejercicios) {
    final repsPlan = e['repsPlanificadas'] ?? 0;
    final repsReal = e['repsRealizadas'] ?? 0;
    if (repsReal < repsPlan) return false;
  }
  return true;
}

// Semana perfecta: cumplir el 100% de las sesiones y ejercicios planificados en una semana
Future<bool> semanaPerfecta(String uid, DateTime semana) async {
  final inicio = semana.subtract(Duration(days: semana.weekday - 1));
  final fin = inicio.add(const Duration(days: 6));
  final snap = await FirebaseFirestore.instance
      .collection('sesiones')
      .where('uid', isEqualTo: uid)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(fin))
      .get();
  for (var doc in snap.docs) {
    final ejercicios = doc['exercises'] as List<dynamic>? ?? [];
    for (var e in ejercicios) {
      final repsPlan = e['repsPlanificadas'] ?? 0;
      final repsReal = e['repsRealizadas'] ?? 0;
      if (repsReal < repsPlan) return false;
    }
  }
  return true;
}

}