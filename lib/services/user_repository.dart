import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario.dart';
import '../services/routine_service.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final RoutineService? routineService;

  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.routineService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? currentUid() => _auth.currentUser?.uid;

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserDoc(String uid) {
    return _firestore.collection('usuarios').doc(uid).snapshots();
  }

  Future<Usuario?> fetchUsuario(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return Usuario.fromMap(doc.data()!, uid); // usa el factory del modelo
  }

  Future<Map<String, dynamic>?> fetchUsuarioRaw(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<List<Object?>> fetchSessions({
    required String uid,
    DateTime? since,
    int limit = 0,
  }) async {
    Query q = _firestore.collection('sesiones').where('uid', isEqualTo: uid);
    if (since != null) q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    if (limit > 0) q = q.limit(limit);
    final snap = await q.orderBy('date', descending: true).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<Map<String, dynamic>?> fetchRutinaActual(String uid) async {
    final snap = await _firestore
        .collection('rutinas')
        .where('uid', isEqualTo: uid)
        .where('es_actual', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  // Stream en tiempo real de la rutina actual (devuelve null si no hay documento)
  Stream<DocumentSnapshot<Map<String, dynamic>>?> streamRutinaActual(String uid) {
    final q = _firestore
        .collection('rutinas')
        .where('uid', isEqualTo: uid)
        .where('es_actual', isEqualTo: true)
        .limit(1);
    return q.snapshots().map((qs) => qs.docs.isNotEmpty ? qs.docs.first : null);
  }

  // Si necesitas días/ejercicios via RoutineService (interfaz)
  Future<List<String>> fetchRoutineDays(String uid) async {
    if (routineService == null) return [];
    return await routineService!.fetchRoutineDays(uid);
  }

  Future<List> fetchExercisesForDay(String uid, String day) async {
    if (routineService == null) return [];
    return await routineService!.fetchExercisesForDay(uid, day);
  }

  // Stream del plan nutricional del usuario (doc id = uid)
  Stream<DocumentSnapshot<Map<String, dynamic>>?> streamNutritionPlan(String uid) {
    final ref = _firestore.collection('nutrition_plans').doc(uid);
    return ref.snapshots().map((doc) => doc.exists ? doc : null);
  }

  // Cuenta asistencias en los últimos `days` días desde la subcolección usuarios/{uid}/asistencias
  Stream<int> streamAsistenciasCountLastNDays(String uid, int days) {
    final col = _firestore.collection('usuarios').doc(uid).collection('asistencias');
    final since = DateTime.now().subtract(Duration(days: days));
    return col.snapshots().map((qs) {
      int count = 0;
      for (final d in qs.docs) {
        final m = d.data();
        final dynamic tsRaw = m['ts'] ?? m['fecha'] ?? m['date'] ?? m['createdAt'];
        DateTime? dt;
        if (tsRaw is Timestamp) dt = tsRaw.toDate();
        else if (tsRaw is String) dt = DateTime.tryParse(tsRaw);
        if (dt != null && dt.isAfter(since)) count++;
      }
      return count;
    }).handleError((_) => 0);
  }
}