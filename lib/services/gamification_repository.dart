import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gamification.dart';
import '../models/logro.dart';

class GamificationRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  GamificationRepository(this.firestore, this.auth);

  CollectionReference<GamificationStats> get refUsuarios =>
      firestore.collection('usuarios').withConverter<GamificationStats>(
            fromFirestore: GamificationStats.fromFirestore,
            toFirestore: (stats, _) => stats.toFirestore(),
          );

  CollectionReference<Logro> logrosRef(String uid) =>
      refUsuarios.doc(uid).collection('logros').withConverter<Logro>(
            fromFirestore: Logro.fromFirestore,
            toFirestore: (logro, _) => logro.toFirestore(),
          );

  CollectionReference<Map<String, dynamic>> asistenciasRef(String uid) =>
      refUsuarios.doc(uid).collection('asistencias');

  Stream<GamificationStats?> statsStream(String uid) {
    return refUsuarios.doc(uid).snapshots().map((snap) => snap.data());
  }

  Stream<List<Logro>> logrosRecientesStream(String uid, {int limit = 20}) {
    return logrosRef(uid)
        .orderBy('otorgadoEn', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> initStatsIfMissing(String uid) async {
    final doc = await refUsuarios.doc(uid).get();
    if (!doc.exists) {
      await refUsuarios.doc(uid).set(const GamificationStats(
            puntos: 0,
            rachaActual: 0,
            rachaRecord: 0,
            ultimaAsistencia: null,
          ));
    }
  }
Future<bool> existeLogro(String uid, String logroId) async {
    final doc = await logrosRef(uid).doc(logroId).get();
    return doc.exists;
  }
  Future<bool> existeAsistenciaDelDia(String uid, DateTime hoy) async {
    final docId = keyDia(hoy);
    final doc = await asistenciasRef(uid).doc(docId).get();
    return doc.exists;
  }

  Future<void> crearAsistenciaDelDia(String uid, DateTime hoy,
      {String source = "sesion"}) async {
    final docId = keyDia(hoy);
    await asistenciasRef(uid).doc(docId).set({
      'fecha': FieldValue.serverTimestamp(),
      'source': source,
    });
  }

  Future<void> incrementarPuntos(String uid, int puntos) async {
    await refUsuarios.doc(uid).update({
      'puntos': FieldValue.increment(puntos),
    });
  }

  Future<void> actualizarRachaYRecord(String uid,
      {required int nuevaRacha,
      required DateTime hoy,
      required bool actualizarUltima}) async {
    final Map<String, dynamic> updates = {
      'rachaActual': nuevaRacha,
    };
    if (actualizarUltima) {
      updates['ultimaAsistencia'] = Timestamp.fromDate(hoy);
    }
    // Actualiza récord si corresponde
    final doc = await refUsuarios.doc(uid).get();
    final stats = doc.data();
    if (stats != null && nuevaRacha > stats.rachaRecord) {
      updates['rachaRecord'] = nuevaRacha;
    }
    await refUsuarios.doc(uid).update(updates);
  }

  Future<void> otorgarLogro(String uid, Logro logro) async {
    final docId =
        logro.periodo != null ? '${logro.tipo}:${logro.periodo}' : logro.id;
    await logrosRef(uid).doc(docId).set(logro);
  }
}
