import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:gymtrack_app/services/chatbot/chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  final ChatService chat;
  const ChatbotScreen({super.key, required this.chat});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  // Estado
  bool _sending = false;
  bool _didSeedWelcome = false; // evita insertar bienvenida varias veces
  DateTime? _lastSendAt;
  String? _lastSentText;

  // Firestore
  late final String _uid;
  late final CollectionReference<Map<String, dynamic>> _messagesRef;

  // Chips de sugerencias (podés cambiarlas o cargarlas desde Firestore)
  final List<String> _quickSuggestions = const <String>[
    'Horarios del gimnasio',
    'Planes y precios',
    '¿Cómo pauso mi membresía?',
    'Ubicación y contacto',
  ];

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _messagesRef = FirebaseFirestore.instance
        .collection('chat_sessions')
        .doc(_uid)
        .collection('messages');
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ===== Helpers =====

  Future<void> _persistMessage({
    required String from, // 'user' | 'bot'
    required String text,
  }) async {
    final now = DateTime.now();
    await _messagesRef.add({
      'from': from,
      'text': text,
      'ts': FieldValue.serverTimestamp(),
      // TTL: Firestore eliminará cuando expiresAt < now (habilitar policy en consola)
      'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
    });
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 160,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ===== Envío con anti‑spam =====
  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    // Evitar duplicado inmediato
    if (_lastSentText != null && _lastSentText == text) {
      return;
    }

    // Cooldown mínimo entre envíos
    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastSendAt = now;
    _lastSentText = text;

    setState(() => _sending = true);
    _input.clear();

    try {
      // 1) guarda mensaje del usuario
      await _persistMessage(from: 'user', text: text);
      _scrollToBottomSoon();

      // 2) pide respuesta al servicio
      final reply = await widget.chat.sendMessage(text);

      // 3) guarda respuesta del bot
      await _persistMessage(from: 'bot', text: reply);
      _scrollToBottomSoon();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enviando mensaje: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reiniciar chat'),
        content: const Text('Esto borrará todo el historial de esta conversación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _resetConversation();
    }
  }

  Future<void> _resetConversation() async {
    // Borra todos los mensajes (se requiere allow delete en reglas)
    final snap = await _messagesRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();

    // Resetea estado del servicio (si usás IA con sesión)
    await widget.chat.reset();

    // Mensaje de bienvenida
    await _persistMessage(
      from: 'bot',
      text: '¡Hola! Soy el asistente de GymTrack. ¿En qué te ayudo?',
    );
    _scrollToBottomSoon();
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot Interactivo'),
        actions: [
          IconButton(
            tooltip: 'Reiniciar conversación',
            onPressed: _confirmReset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chips de sugerencias
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _quickSuggestions.map((label) {
                return ActionChip(
                  label: Text(label),
                  onPressed: _sending
                      ? null
                      : () {
                          _input.text = label;
                          _send();
                        },
                );
              }).toList(),
            ),
          ),

          // Mensajes (stream en vivo)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  _messagesRef.orderBy('ts', descending: false).snapshots(),
              builder: (context, snapshot) {
                // Cargando
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Semilla de bienvenida (una sola vez)
                if (docs.isEmpty && !_didSeedWelcome) {
                  _didSeedWelcome = true;
                  _persistMessage(
                    from: 'bot',
                    text:
                        '¡Hola! Soy el asistente de GymTrack. Preguntame por horarios, planes o tips.',
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottomSoon();
                });

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length + (_sending ? 1 : 0),
                  itemBuilder: (_, i) {
                    // Typing bubble al final
                    if (_sending && i == docs.length) {
                      return const _TypingBubble();
                    }

                    final data = docs[i].data();
                    final fromUser = (data['from'] == 'user');
                    final text = (data['text'] ?? '').toString();

                    return _MessageBubble(
                      fromUser: fromUser,
                      text: text,
                    );
                  },
                );
              },
            ),
          ),

          // Input
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Escribí tu consulta...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool fromUser;
  final String text;
  const _MessageBubble({required this.fromUser, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = fromUser
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade300;
    final align =
        fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final txtColor = fromUser ? Colors.white : Colors.black87;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: txtColor)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Escribiendo...'),
          ],
        ),
      ),
    );
  }
}
