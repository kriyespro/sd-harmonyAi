import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class CreateRelationshipScreen extends StatefulWidget {
  const CreateRelationshipScreen({super.key});

  @override
  State<CreateRelationshipScreen> createState() => _CreateRelationshipScreenState();
}

class _CreateRelationshipScreenState extends State<CreateRelationshipScreen> {
  String _selectedType = 'couple';
  bool _loading = false;
  String? _inviteLink;

  final _types = [
    ('couple', '💑', 'Couple', 'Romantic partner'),
    ('parent_child', '👨‍👧', 'Parent / Child', 'Family bond'),
    ('friends', '🤝', 'Friends', 'Close friendship'),
    ('business', '💼', 'Business', 'Co-founder or partner'),
  ];

  Future<void> _create() async {
    setState(() => _loading = true);
    final rel = await ApiService.createRelationship(_selectedType);
    setState(() => _loading = false);
    if (rel != null && rel.inviteLink != null) {
      setState(() => _inviteLink = rel.inviteLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Relationship')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _inviteLink == null ? _buildTypeSelector() : _buildInviteShare(),
      ),
    );
  }

  Widget _buildTypeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What type of relationship?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          const Text("You'll get an invite link to share with the other person.", style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            children: _types.map((t) {
              final isSelected = _selectedType == t.$1;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t.$1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFfff1f2) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? const Color(0xFFf43f5e) : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$2, style: const TextStyle(fontSize: 28)),
                      const Spacer(),
                      Text(t.$3, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFFf43f5e) : const Color(0xFF111827))),
                      Text(t.$4, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loading ? null : _create,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Create & Get Invite Link'),
          ),
        ],
      );

  Widget _buildInviteShare() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Text('🔗', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Share this invite', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text('Send this link to your partner. They tap it to join.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Row(
              children: [
                Expanded(child: Text(_inviteLink!, style: const TextStyle(fontSize: 13, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _inviteLink!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied!'), backgroundColor: Color(0xFF22c55e)));
                  },
                  child: const Text('Copy', style: TextStyle(color: Color(0xFFf43f5e), fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: 'Join me on HarmonyAI: $_inviteLink'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share link copied! Paste in WhatsApp or Messages.'), backgroundColor: Color(0xFF22c55e)),
                );
              }
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Copy to share via WhatsApp / Messages'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFf43f5e), side: const BorderSide(color: Color(0xFFf43f5e))),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done'),
          ),
        ],
      );
}
