import 'package:flutter/material.dart';
import '../models/relationship.dart';
import '../services/api_service.dart';
import 'premium_screen.dart';

class WeeklyReportScreen extends StatefulWidget {
  final Relationship relationship;
  final int myId;

  const WeeklyReportScreen({super.key, required this.relationship, required this.myId});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  Map<String, dynamic>? _report;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    final result = await ApiService.generateWeeklyReport(widget.relationship.id);
    setState(() {
      _report = result;
      _generating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Report'),
        actions: [
          if (!_generating)
            TextButton(
              onPressed: _generate,
              child: const Text('Regenerate', style: TextStyle(color: Color(0xFFf43f5e))),
            ),
        ],
      ),
      body: _generating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFf43f5e)),
                  SizedBox(height: 16),
                  Text('Generating your weekly report…', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                ],
              ),
            )
          : _report == null
              ? const Center(child: Text('Report generation failed. Try again.', style: TextStyle(color: Color(0xFF6B7280))))
              : _report!['error'] == 'limit_reached'
                  ? _LimitReachedCard(onUpgrade: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen(featureBlocked: 'weekly reports'))))
                  : _report!.containsKey('error')
                      ? Center(child: Text(_report!['error'], style: const TextStyle(color: Color(0xFFef4444))))
                  : RefreshIndicator(
                      onRefresh: _generate,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeadlineCard(headline: _report!['headline'] ?? ''),
                            const SizedBox(height: 16),
                            if (_report!['mood_summary'] != null) _SummaryCard(title: 'Mood', content: _report!['mood_summary']),
                            const SizedBox(height: 12),
                            if (_report!['connection_summary'] != null) _SummaryCard(title: 'Connection', content: _report!['connection_summary']),
                            const SizedBox(height: 16),
                            if (_report!['highlights'] != null) _ListCard(title: 'Highlights', items: List<String>.from(_report!['highlights']), color: const Color(0xFF22c55e), icon: Icons.check_circle_outline),
                            const SizedBox(height: 12),
                            if (_report!['areas_to_watch'] != null && (_report!['areas_to_watch'] as List).isNotEmpty)
                              _ListCard(title: 'Areas to Watch', items: List<String>.from(_report!['areas_to_watch']), color: const Color(0xFFf59e0b), icon: Icons.warning_amber_outlined),
                            const SizedBox(height: 16),
                            if (_report!['this_week_focus'] != null) _FocusCard(focus: _report!['this_week_focus']),
                            const SizedBox(height: 16),
                            if (_report!['affirmation'] != null) _AffirmationCard(text: _report!['affirmation']),
                            const SizedBox(height: 16),
                            _CounselingCard(),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final String headline;
  const _HeadlineCard({required this.headline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFf43f5e), Color(0xFFec4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Weekly Report', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(headline, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3)),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String content;
  const _SummaryCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.6)),
      ]),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;
  const _ListCard({required this.title, required this.items, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.4))),
          ]),
        )),
      ]),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String focus;
  const _FocusCard({required this.focus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFf43f5e), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('THIS WEEK\'S FOCUS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(focus, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
      ]),
    );
  }
}

class _AffirmationCard extends StatelessWidget {
  final String text;
  const _AffirmationCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('"$text"', style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic, height: 1.6), textAlign: TextAlign.center),
      ),
    );
  }
}

class _LimitReachedCard extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _LimitReachedCard({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF4f46e5)]),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: 36)),
          ),
          const SizedBox(height: 20),
          const Text('Weekly Reports Locked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text('You\'ve used your free weekly report this month. Upgrade to generate unlimited reports.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7c3aed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Upgrade to Premium', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CounselingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22c55e).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.support_agent_rounded, color: Color(0xFF22c55e), size: 18),
          SizedBox(width: 8),
          Text('Professional Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF14532d))),
        ]),
        const SizedBox(height: 6),
        const Text('AI coaching is powerful but a therapist can help even more. Trusted resources:', style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4)),
        const SizedBox(height: 10),
        _ResourceLink(name: 'iCall', description: 'Online Therapy · India', url: 'icallhelpline.org'),
        _ResourceLink(name: 'Vandrevala Foundation', description: '24/7 Helpline · India', url: 'vandrevalafoundation.com'),
        _ResourceLink(name: 'BetterHelp', description: 'Online Therapy · Global', url: 'betterhelp.com'),
      ]),
    );
  }
}

class _ResourceLink extends StatelessWidget {
  final String name;
  final String description;
  final String url;
  const _ResourceLink({required this.name, required this.description, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(url))),
        child: Row(children: [
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF22c55e)),
          const SizedBox(width: 6),
          Expanded(child: RichText(
            text: TextSpan(children: [
              TextSpan(text: '$name — ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF14532d))),
              TextSpan(text: description, style: const TextStyle(fontSize: 12, color: Color(0xFF166534))),
            ]),
          )),
        ]),
      ),
    );
  }
}
