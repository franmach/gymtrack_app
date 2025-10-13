import 'package:flutter/material.dart';
import 'package:gymtrack_app/services/chatbot/chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  final ChatService chat;
  final Map<String, dynamic>? userContext; // datos personales

  const ChatbotScreen({
    super.key,
    required this.chat,
    this.userContext,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<_Msg> _messages = [];
  bool _sending = false;

  DateTime? _lastSendAt;
  String? _lastSentText;

  // Sugerencias rápidas (pueden modificarse)
  final List<String> _quickSuggestions = const [
    '¿Cuál es el mejor ejercicio para abdominales?',
    'Dame una rutina corta para casa',
    '¿Qué puedo comer antes de entrenar?',
    '¿Cómo mejorar mi resistencia?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    // Anti-spam: evita duplicados o envío rápido
    if (_lastSentText != null && _lastSentText == text) return;
    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastSendAt = now;
    _lastSentText = text;

    setState(() {
      _messages.add(_Msg(fromUser: true, text: text));
      _sending = true;
    });
    _input.clear();
    _scrollToBottomSoon();

    try {
      // Consulta a Gemini con contexto del usuario
      final reply = await widget.chat
          .sendMessage(text, userContext: widget.userContext ?? {});
      setState(() {
        _messages.add(_Msg(fromUser: false, text: reply));
      });
      _scrollToBottomSoon();
    } catch (e) {
      setState(() {
        _messages.add(
          _Msg(fromUser: false, text: '⚠️ Error: $e'),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reiniciar chat'),
        content: const Text('Esto borrará toda la conversación actual.'),
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
    await widget.chat.reset();
    setState(() => _messages.clear());
    _scrollToBottomSoon();
  }

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
          // Chips de sugerencias rápidas
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

          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (_, i) {
                if (_sending && i == _messages.length) {
                  return const _TypingBubble();
                }
                final msg = _messages[i];
                return _MessageBubble(fromUser: msg.fromUser, text: msg.text);
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

// ======= Widgets auxiliares =======

class _Msg {
  final bool fromUser;
  final String text;
  _Msg({required this.fromUser, required this.text});
}

class _MessageBubble extends StatelessWidget {
  final bool fromUser;
  final String text;
  const _MessageBubble({required this.fromUser, required this.text});

  @override
  Widget build(BuildContext context) {
    final color =
        fromUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade300;
    final align = fromUser ? Alignment.centerRight : Alignment.centerLeft;
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