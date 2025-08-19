// lib/services/chatbot/firestore_faq_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_service.dart';

class FirestoreFaqService implements ChatService {
  List<Map<String, dynamic>>? _faq;

  Future<void> _loadFaq() async {
    if (_faq != null) return;
    final snap = await FirebaseFirestore.instance.collection('chatbot_faq').get();
    _faq = snap.docs.map((d) => d.data()).cast<Map<String, dynamic>>().toList();
  }

  String _normalize(String s) {
    final lower = s.toLowerCase();
    // quita tildes básico
    const from = 'áéíóúüñ';
    const to   = 'aeiouun';
    var out = lower;
    for (int i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  double _score(String text, List<String> keywords) {
    if (keywords.isEmpty) return 0;
    final t = _normalize(text);
    int hits = 0;
    for (final k in keywords) {
      final kn = _normalize(k);
      if (t.contains(kn)) hits++;
    }
    // proporción de keywords “matcheadas”
    return hits / keywords.length;
  }

  @override
  Future<String> sendMessage(String userText) async {
    await _loadFaq();
    if (_faq!.isEmpty) return 'Aún no tengo información cargada.';

    // rankea por score y toma la mejor si supera umbral
    final ranked = _faq!
        .map((it) => {
              'answer': (it['answer'] ?? '').toString(),
              'score': _score(userText, List<String>.from(it['keywords'] ?? const [])),
            })
        .toList()
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    final best = ranked.first;
    return (best['score'] as double) >= 0.34
        ? (best['answer'] as String)
        : 'No encuentro esa información en mi base.';
  }

  @override
  Future<void> reset() async {
    _faq = null; // fuerza recarga
  }
}