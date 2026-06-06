import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/relationship.dart';
import '../models/mood.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'ai_coach_screen.dart';
import 'weekly_report_screen.dart';
import 'calendar_screen.dart';
import 'premium_screen.dart';

class RelationshipDetailScreen extends StatefulWidget {
  final Relationship relationship;
  final int myId;

  const RelationshipDetailScreen({super.key, required this.relationship, required this.myId});

  @override
  State<RelationshipDetailScreen> createState() => _RelationshipDetailScreenState();
}

class _RelationshipDetailScreenState extends State<RelationshipDetailScreen> {
  HealthScore? _health;
  List<MoodEntry> _moods = [];
  List<ConflictEntry> _conflicts = [];
  bool _loading = true;
  int _connectionScore = 7;
  String? _selectedMood;
  final _moodNoteCtrl = TextEditingController();
  Map<String, dynamic>? _aiUsage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _moodNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getHealthScore(widget.relationship.id),
      ApiService.getMoodHistory(widget.relationship.id),
      ApiService.getConflicts(widget.relationship.id),
      ApiService.getBillingStatus(),
    ]);
    setState(() {
      _health = results[0] as HealthScore?;
      _moods = results[1] as List<MoodEntry>;
      _conflicts = results[2] as List<ConflictEntry>;
      final billing = results[3] as Map<String, dynamic>?;
      _aiUsage = billing?['usage'] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  Future<void> _submitMood() async {
    if (_selectedMood == null) return;
    await ApiService.logMood(widget.relationship.id, _selectedMood!, note: _moodNoteCtrl.text);
    await ApiService.logConnectionScore(widget.relationship.id, _connectionScore);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Check-in saved'), backgroundColor: Color(0xFF22c55e)));
      _moodNoteCtrl.clear();
      setState(() => _selectedMood = null);
    }
    await _load();
  }

  Color get _scoreColor {
    final c = _health?.color ?? 'blue';
    return switch (c) {
      'green' => const Color(0xFF22c55e),
      'yellow' => const Color(0xFFeab308),
      'red' => const Color(0xFFef4444),
      _ => const Color(0xFF3b82f6),
    };
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.relationship.otherUser(widget.myId);
    return Scaffold(
      appBar: AppBar(
        title: Text(other.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CalendarScreen(relationship: widget.relationship, myId: widget.myId),
            )),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HealthScoreCard(health: _health, scoreColor: _scoreColor),
                    const SizedBox(height: 20),
                    _CheckInCard(
                      selectedMood: _selectedMood,
                      connectionScore: _connectionScore,
                      noteCtrl: _moodNoteCtrl,
                      onMoodSelect: (m) => setState(() => _selectedMood = m),
                      onScoreChange: (v) => setState(() => _connectionScore = v),
                      onSubmit: _submitMood,
                    ),
                    const SizedBox(height: 20),
                    _AIToolsCard(relationship: widget.relationship, myId: widget.myId, aiUsage: _aiUsage),
                    const SizedBox(height: 20),
                    _ConflictSection(
                      conflicts: _conflicts,
                      relId: widget.relationship.id,
                      onAdded: _load,
                    ),
                    const SizedBox(height: 20),
                    if (_moods.isNotEmpty) _MoodHistory(moods: _moods),
                  ],
                ),
              ),
            ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final HealthScore? health;
  final Color scoreColor;

  const _HealthScoreCard({this.health, required this.scoreColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Relationship Health', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF111827))),
              if (health != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: scoreColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(health!.label, style: TextStyle(color: scoreColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (health == null)
            const Center(child: Text('No data yet — start checking in daily.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)))
          else
            Row(
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: health!.overall / 100,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                      ),
                      Text('${health!.overall}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _ScoreRow('Mood', health!.moodScore),
                      const SizedBox(height: 8),
                      _ScoreRow('Connection', health!.connectionScore),
                      const SizedBox(height: 8),
                      _ScoreRow('Conflict', health!.conflictScore),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreRow(this.label, this.score);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFf43f5e)),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$score', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      ],
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final String? selectedMood;
  final int connectionScore;
  final TextEditingController noteCtrl;
  final Function(String) onMoodSelect;
  final Function(int) onScoreChange;
  final VoidCallback onSubmit;

  const _CheckInCard({
    this.selectedMood,
    required this.connectionScore,
    required this.noteCtrl,
    required this.onMoodSelect,
    required this.onScoreChange,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final moods = [
      ('happy', '😊'),
      ('neutral', '😐'),
      ('sad', '😔'),
      ('angry', '😡'),
      ('stressed', '😰'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Check-in", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          const Text('How do you feel?', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: moods.map((m) {
              final isSelected = selectedMood == m.$1;
              return GestureDetector(
                onTap: () => onMoodSelect(m.$1),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFfff1f2) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? const Color(0xFFf43f5e) : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1),
                  ),
                  child: Center(child: Text(m.$2, style: const TextStyle(fontSize: 24))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Add a note (optional)', hintText: 'How was your day?'),
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          Text('Connection today: $connectionScore/10', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          Slider(
            value: connectionScore.toDouble(),
            min: 1, max: 10, divisions: 9,
            activeColor: const Color(0xFFf43f5e),
            onChanged: (v) => onScoreChange(v.round()),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: selectedMood != null ? onSubmit : null,
            child: const Text('Save Check-in'),
          ),
        ],
      ),
    );
  }
}

class _ConflictSection extends StatelessWidget {
  final List<ConflictEntry> conflicts;
  final int relId;
  final VoidCallback onAdded;

  const _ConflictSection({required this.conflicts, required this.relId, required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Conflict Journal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF111827))),
              GestureDetector(
                onTap: () => _showAddConflict(context),
                child: const Text('+ Log', style: TextStyle(color: Color(0xFFf43f5e), fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (conflicts.isEmpty)
            const Text('No conflicts logged — great sign! 🎉', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14))
          else
            ...conflicts.take(5).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.resolved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c.resolved ? const Color(0xFF22c55e) : const Color(0xFFef4444),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(c.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 6),
                                Text('Severity ${c.severity}/5', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                              ]),
                              const SizedBox(height: 4),
                              Text(c.description, style: const TextStyle(fontSize: 13, color: Color(0xFF374151)), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (c.resolved) const Icon(Icons.check_circle, color: Color(0xFF22c55e), size: 18),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  void _showAddConflict(BuildContext context) {
    final categories = ['money', 'time', 'work', 'family', 'trust', 'communication', 'other'];
    String selectedCategory = categories[0];
    int severity = 2;
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log Conflict', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setModal(() => selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'What happened?', hintText: 'Describe briefly...'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Text('Severity: $severity/5', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              Slider(
                value: severity.toDouble(), min: 1, max: 5, divisions: 4,
                activeColor: const Color(0xFFf43f5e),
                onChanged: (v) => setModal(() => severity = v.round()),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await ApiService.logConflict(relId, selectedCategory, descCtrl.text, severity);
                  Navigator.pop(ctx);
                  onAdded();
                },
                child: const Text('Log Conflict'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AIToolsCard extends StatelessWidget {
  final Relationship relationship;
  final int myId;
  final Map<String, dynamic>? aiUsage;
  const _AIToolsCard({required this.relationship, required this.myId, this.aiUsage});

  bool _isLocked(String feature) {
    if (aiUsage == null) return false;
    final u = aiUsage![feature] as Map<String, dynamic>?;
    if (u == null) return false;
    final used = (u['used'] as int?) ?? 0;
    final limit = (u['limit'] as int?) ?? 0;
    return used >= limit;
  }

  String _usageLabel(String feature) {
    if (aiUsage == null) return '';
    final u = aiUsage![feature] as Map<String, dynamic>?;
    if (u == null) return '';
    return '${u['used']}/${u['limit']}';
  }

  void _navigateOrPaywall(BuildContext ctx, Widget screen, String feature) {
    final isPremium = ctx.read<AuthProvider>().isPremium;
    if (!isPremium && _isLocked(feature)) {
      Navigator.push(ctx, MaterialPageRoute(
        builder: (_) => PremiumScreen(featureBlocked: feature),
      ));
    } else {
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AuthProvider>().isPremium;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('AI Engine', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF111827))),
            const SizedBox(width: 6),
            const Text('✦', style: TextStyle(color: Color(0xFFf43f5e), fontSize: 14)),
            const Spacer(),
            if (!isPremium)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF4f46e5)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Go Premium ✦', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _AIButton(
                icon: Icons.psychology_outlined,
                label: 'AI Coach',
                color: const Color(0xFFf43f5e),
                locked: !isPremium && _isLocked('coach'),
                usage: isPremium ? null : _usageLabel('coach'),
                onTap: () => _navigateOrPaywall(context, AiCoachScreen(relationship: relationship, myId: myId), 'coach'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AIButton(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                color: const Color(0xFF0ea5e9),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CalendarScreen(relationship: relationship, myId: myId),
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AIButton(
                icon: Icons.bar_chart_rounded,
                label: 'Report',
                color: const Color(0xFF6366f1),
                locked: !isPremium && _isLocked('report'),
                usage: isPremium ? null : _usageLabel('report'),
                onTap: () => _navigateOrPaywall(context, WeeklyReportScreen(relationship: relationship, myId: myId), 'report'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _AIButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool locked;
  final String? usage;
  const _AIButton({required this.icon, required this.label, required this.color, required this.onTap, this.locked = false, this.usage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: locked ? const Color(0xFFF3F4F6) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: locked ? const Color(0xFFE5E7EB) : color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Stack(alignment: Alignment.topRight, children: [
            Icon(icon, color: locked ? const Color(0xFF9CA3AF) : color, size: 26),
            if (locked)
              Positioned(
                right: -2, top: -2,
                child: Container(
                  width: 14, height: 14,
                  decoration: const BoxDecoration(color: Color(0xFF7c3aed), shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.lock, size: 8, color: Colors.white)),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: locked ? const Color(0xFF9CA3AF) : color)),
          if (usage != null && usage!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(usage!, style: TextStyle(fontSize: 10, color: locked ? const Color(0xFFef4444) : const Color(0xFF9CA3AF))),
          ],
        ]),
      ),
    );
  }
}

class _MoodHistory extends StatelessWidget {
  final List<MoodEntry> moods;

  const _MoodHistory({required this.moods});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mood History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: moods.take(14).map((m) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.emoji),
                  const SizedBox(width: 4),
                  Text('${m.date.day}/${m.date.month}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
