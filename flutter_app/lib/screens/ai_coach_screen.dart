import 'package:flutter/material.dart';
import '../models/relationship.dart';
import '../services/api_service.dart';
import 'premium_screen.dart';

class AiCoachScreen extends StatefulWidget {
  final Relationship relationship;
  final int myId;

  const AiCoachScreen({super.key, required this.relationship, required this.myId});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final history = await ApiService.getChatHistory(widget.relationship.id);
    setState(() {
      _messages = history;
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || _sending) return;

    setState(() {
      _messages.add({'role': 'user', 'content': msg});
      _sending = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    final result = await ApiService.sendCoachMessage(widget.relationship.id, msg);
    setState(() {
      _sending = false;
      if (result['error'] == 'limit_reached') {
        _messages.add({'role': 'assistant', 'content': '🔒 You\'ve reached your free message limit. Upgrade to Premium for unlimited coaching.'});
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen(featureBlocked: 'AI coaching')));
          }
        });
      } else if (result['reply'] != null) {
        _messages.add({'role': 'assistant', 'content': result['reply']});
      }
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.relationship.otherUser(widget.myId);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFf43f5e), Color(0xFFec4899)]),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('HarmonyAI Coach', style: TextStyle(fontSize: 15)),
            Text(other.fullName, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.normal)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_messages.isEmpty ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (_messages.isEmpty) {
                        return _WelcomeMessage(relType: widget.relationship.relationshipType);
                      }
                      final m = _messages[i];
                      return _MessageBubble(role: m['role'], content: m['content']);
                    },
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _TypingIndicator(),
            ),
          _InputBar(ctrl: _msgCtrl, onSend: _send, sending: _sending),
        ],
      ),
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  final String relType;
  const _WelcomeMessage({required this.relType});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFf43f5e), Color(0xFFec4899)]),
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              'Hi! I\'m your HarmonyAI relationship coach. I can help with your $relType relationship — conflict patterns, communication tips, or just thinking things through. What\'s on your mind?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String role;
  final String content;
  const _MessageBubble({required this.role, required this.content});

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFf43f5e), Color(0xFFec4899)]),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFf43f5e) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : const Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFf43f5e), Color(0xFFec4899)]),
          shape: BoxShape.circle,
        ),
        child: const Center(child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Dot(delay: 0),
          const SizedBox(width: 4),
          _Dot(delay: 150),
          const SizedBox(width: 4),
          _Dot(delay: 300),
        ]),
      ),
    ]);
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(color: Color(0xFF9CA3AF), shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool sending;
  const _InputBar({required this.ctrl, required this.onSend, required this.sending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Ask your coach…',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => onSend(),
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: sending ? null : onSend,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFf43f5e), Color(0xFFec4899)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: sending
                ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
