import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/relationship.dart';
import 'relationship_detail_screen.dart';
import 'create_relationship_screen.dart';
import 'calendar_screen.dart';
import 'premium_screen.dart';

// ─── Palette ───────────────────────────────────────────────────────────────
const _rose = Color(0xFFf43f5e);
const _roseLight = Color(0xFFfff1f2);
const _roseMid = Color(0xFFec4899);
const _purple = Color(0xFF7c3aed);
const _indigo = Color(0xFF4f46e5);
const _dark = Color(0xFF0f0c29);
const _darkMid = Color(0xFF302b63);
const _slate = Color(0xFF111827);
const _gray = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

const _relGradients = {
  'couple': [Color(0xFFf43f5e), Color(0xFFec4899)],
  'parent_child': [Color(0xFF4f46e5), Color(0xFF7c3aed)],
  'friends': [Color(0xFF059669), Color(0xFF0891b2)],
  'business': [Color(0xFFd97706), Color(0xFFea580c)],
};

// ─── HomeScreen ────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  List<Relationship> _relationships = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  bool _loading = true;
  Relationship? _selectedRel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rels = await ApiService.getRelationships();
    final events = await _fetchUpcomingEvents(rels);
    if (!mounted) return;
    setState(() {
      _relationships = rels;
      _upcomingEvents = events;
      _loading = false;
      if (_selectedRel == null && rels.isNotEmpty) _selectedRel = rels.first;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchUpcomingEvents(List<Relationship> rels) async {
    final all = <Map<String, dynamic>>[];
    for (final r in rels) {
      final evts = await ApiService.getEvents(r.id);
      for (final e in evts) {
        if (e['date'] != null) {
          try {
            final d = DateTime.parse(e['date'] as String);
            if (d.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
              all.add({...e, '_relType': r.relationshipType, '_relId': r.id});
            }
          } catch (_) {}
        }
      }
    }
    all.sort((a, b) {
      try {
        return DateTime.parse(a['date'] as String).compareTo(DateTime.parse(b['date'] as String));
      } catch (_) {
        return 0;
      }
    });
    return all.take(4).toList();
  }

  Widget _tab(int i) {
    return switch (i) {
      0 => _HomeTab(
          relationships: _relationships,
          upcomingEvents: _upcomingEvents,
          loading: _loading,
          onRefresh: _load,
          onSwitchToRelationships: () => setState(() => _navIndex = 1),
        ),
      1 => _RelationshipsTab(
          relationships: _relationships,
          loading: _loading,
          myId: context.read<AuthProvider>().user?.id ?? 0,
          onRefresh: _load,
        ),
      2 => _selectedRel != null
          ? CalendarScreen(
              relationship: _selectedRel!,
              myId: context.read<AuthProvider>().user?.id ?? 0,
            )
          : const _Placeholder(label: 'No relationship selected.'),
      _ => _ProfileTab(user: context.read<AuthProvider>().user),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: IndexedStack(
          index: _navIndex,
          children: List.generate(4, _tab),
        ),
        bottomNavigationBar: _BottomNav(
          index: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation ──────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', active: index == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.favorite_rounded, label: 'Bonds', active: index == 1, onTap: () => onTap(1)),
              _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendar', active: index == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', active: index == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: active ? _roseLight : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 22, color: active ? _rose : _gray),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? _rose : _gray)),
        ]),
      ),
    );
  }
}

// ─── HOME TAB ───────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final List<Relationship> relationships;
  final List<Map<String, dynamic>> upcomingEvents;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onSwitchToRelationships;

  const _HomeTab({
    required this.relationships,
    required this.upcomingEvents,
    required this.loading,
    required this.onRefresh,
    required this.onSwitchToRelationships,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isPremium = auth.isPremium;

    return RefreshIndicator(
      color: _rose,
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Hero Header ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 230,
            floating: false,
            pinned: true,
            backgroundColor: _dark,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeroHeader(user: user, isPremium: isPremium),
            ),
            title: Row(children: [
              const Text('HarmonyAI', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              const SizedBox(width: 6),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_purple, _indigo]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),

          if (loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: _rose)),
            )
          else ...[
            // ── Stats Row ─────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _StatsRow(
                  relationshipCount: relationships.length,
                  eventCount: upcomingEvents.length,
                ),
              ),
            ),

            // ── Relationship Health Cards ──────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Your Connections',
                  actionLabel: 'See all',
                  onAction: onSwitchToRelationships,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _RelHealthScroll(
                relationships: relationships,
                myId: context.read<AuthProvider>().user?.id ?? 0,
                onAddTap: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRelationshipScreen()),
                  );
                  if (ok == true) onRefresh();
                },
                onCardTap: (rel) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RelationshipDetailScreen(
                        relationship: rel,
                        myId: context.read<AuthProvider>().user?.id ?? 0,
                      ),
                    ),
                  );
                  onRefresh();
                },
              ),
            ),

            // ── Quick Actions ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(title: 'Quick Actions'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _QuickActionsGrid(
                  relationships: relationships,
                  myId: context.read<AuthProvider>().user?.id ?? 0,
                  isPremium: isPremium,
                ),
              ),
            ),

            // ── Upcoming Events ────────────────────────────────────────────
            if (upcomingEvents.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Upcoming Events', actionLabel: 'Calendar', onAction: onSwitchToRelationships),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _UpcomingEventsList(events: upcomingEvents),
                ),
              ),
            ],

            // ── Premium Insight Card ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              sliver: SliverToBoxAdapter(
                child: isPremium
                    ? const _InsightCard()
                    : _UpgradeBanner(
                        onTap: () async {
                          final upgraded = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const PremiumScreen()),
                          );
                          if (upgraded == true) context.read<AuthProvider>().refreshPremiumStatus();
                        },
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Hero Header ────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final dynamic user;
  final bool isPremium;
  const _HeroHeader({required this.user, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final name = user?.firstName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_dark, _darkMid, Color(0xFF24243e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(top: -30, right: -30,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _rose.withOpacity(0.06)))),
          Positioned(bottom: -20, left: -20,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _purple.withOpacity(0.08)))),
          Positioned(top: 40, right: 60,
            child: Container(width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _roseMid.withOpacity(0.06)))),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$greeting,',
                          style: const TextStyle(color: Color(0xFFa5b4fc), fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name.isNotEmpty ? name : 'Friend',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.auto_awesome, size: 12, color: Color(0xFFfbbf24)),
                            SizedBox(width: 5),
                            Text('Small habits build lasting love', style: TextStyle(color: Color(0xFFe2e8f0), fontSize: 12)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_rose, _roseMid]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _rose.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Center(
                          child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (isPremium)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_purple, _indigo]),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF302b63), width: 2),
                            ),
                            child: const Center(child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 8))),
                          ),
                        ),
                    ],
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

// ─── Stats Row ───────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int relationshipCount;
  final int eventCount;
  const _StatsRow({required this.relationshipCount, required this.eventCount});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatCard(value: '7', label: 'Day Streak', icon: Icons.local_fire_department_rounded, color: const Color(0xFFf97316)),
      const SizedBox(width: 10),
      _StatCard(value: '$relationshipCount', label: 'Connections', icon: Icons.favorite_rounded, color: _rose),
      const SizedBox(width: 10),
      _StatCard(value: '$eventCount', label: 'Upcoming', icon: Icons.event_rounded, color: _purple),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _slate, height: 1.1)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _gray, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─── Relationship Health Horizontal Scroll ──────────────────────────────────
class _RelHealthScroll extends StatelessWidget {
  final List<Relationship> relationships;
  final int myId;
  final VoidCallback onAddTap;
  final ValueChanged<Relationship> onCardTap;
  const _RelHealthScroll({required this.relationships, required this.myId, required this.onAddTap, required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        children: [
          ...relationships.map((r) => Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _RelHealthCard(rel: r, myId: myId, onTap: () => onCardTap(r)),
          )),
          _AddRelCard(onTap: onAddTap),
        ],
      ),
    );
  }
}

class _RelHealthCard extends StatefulWidget {
  final Relationship rel;
  final int myId;
  final VoidCallback onTap;
  const _RelHealthCard({required this.rel, required this.myId, required this.onTap});

  @override
  State<_RelHealthCard> createState() => _RelHealthCardState();
}

class _RelHealthCardState extends State<_RelHealthCard> {
  HealthScore? _health;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await ApiService.getHealthScore(widget.rel.id);
    if (mounted) setState(() => _health = h);
  }

  List<Color> get _gradient =>
      _relGradients[widget.rel.relationshipType] ?? [_rose, _roseMid];

  @override
  Widget build(BuildContext context) {
    final other = widget.rel.otherUser(widget.myId);
    final score = _health?.overall ?? 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 158,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: _gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _gradient.first.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(top: -20, right: -20,
              child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(other.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.rel.typeLabel, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(other.firstName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    _health != null ? '$score' : '—',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 2),
                    child: Text('/100', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
                  ),
                  const Spacer(),
                  if (_health != null)
                    _ScoreBadge(label: _health!.label),
                ]),
                const SizedBox(height: 6),
                _ScoreBar(score: score, color: Colors.white),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  const _ScoreBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreBar({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: score / 100,
        backgroundColor: color.withOpacity(0.25),
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: 4,
      ),
    );
  }
}

class _AddRelCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRelCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border, width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _roseLight, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.add_rounded, color: _rose, size: 22),
          ),
          const SizedBox(height: 8),
          const Text('Add Bond', style: TextStyle(color: _slate, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─── Quick Actions Grid ───────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final List<Relationship> relationships;
  final int myId;
  final bool isPremium;
  const _QuickActionsGrid({required this.relationships, required this.myId, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final rel = relationships.isNotEmpty ? relationships.first : null;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _ActionTile(
          icon: Icons.mood_rounded,
          label: 'Log Mood',
          sublabel: 'How are you feeling?',
          gradient: const [Color(0xFFf97316), Color(0xFFef4444)],
          onTap: () {
            if (rel != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => RelationshipDetailScreen(relationship: rel, myId: myId),
              ));
            }
          },
        ),
        _ActionTile(
          icon: Icons.psychology_alt_rounded,
          label: 'AI Coach',
          sublabel: 'Get guidance',
          gradient: const [Color(0xFF7c3aed), Color(0xFF4f46e5)],
          onTap: () {
            if (rel != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => RelationshipDetailScreen(relationship: rel, myId: myId),
              ));
            }
          },
        ),
        _ActionTile(
          icon: Icons.bar_chart_rounded,
          label: 'Patterns',
          sublabel: 'See your trends',
          gradient: const [Color(0xFF059669), Color(0xFF0891b2)],
          onTap: () {
            if (rel != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => RelationshipDetailScreen(relationship: rel, myId: myId),
              ));
            }
          },
        ),
        _ActionTile(
          icon: Icons.assignment_rounded,
          label: 'Weekly Report',
          sublabel: 'Your AI summary',
          gradient: const [Color(0xFFd97706), Color(0xFFdb2777)],
          locked: !isPremium,
          onTap: () {
            if (rel != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => isPremium
                    ? RelationshipDetailScreen(relationship: rel, myId: myId)
                    : const PremiumScreen(),
              ));
            }
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool locked;
  const _ActionTile({required this.icon, required this.label, required this.sublabel, required this.gradient, required this.onTap, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(icon, color: Colors.white, size: 22),
            if (locked) ...[
              const Spacer(),
              const Icon(Icons.lock_rounded, color: Colors.white54, size: 14),
            ],
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(sublabel, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _slate, letterSpacing: -0.2)),
      const Spacer(),
      if (actionLabel != null)
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel!, style: const TextStyle(fontSize: 13, color: _rose, fontWeight: FontWeight.w600)),
        ),
    ]);
  }
}

// ─── Upcoming Events ─────────────────────────────────────────────────────────
class _UpcomingEventsList extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  const _UpcomingEventsList({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: events.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final isLast = i == events.length - 1;
          return _EventTile(event: e, isLast: isLast);
        }).toList(),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;
  const _EventTile({required this.event, required this.isLast});

  IconData _iconForType(String? type) => switch (type) {
    'birthday' => Icons.cake_rounded,
    'anniversary' => Icons.favorite_rounded,
    'vacation' => Icons.flight_rounded,
    'promise' => Icons.handshake_rounded,
    _ => Icons.event_rounded,
  };

  Color _colorForRelType(String? t) => switch (t) {
    'couple' => _rose,
    'parent_child' => _purple,
    'friends' => const Color(0xFF059669),
    _ => _gray,
  };

  String _daysLabel(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      final diff = d.difference(DateTime.now()).inDays;
      if (diff == 0) return 'Today!';
      if (diff == 1) return 'Tomorrow';
      return 'in $diff days';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = event['event_type'] as String?;
    final relType = event['_relType'] as String?;
    final color = _colorForRelType(relType);
    final daysLabel = _daysLabel(event['date'] as String?);
    final isUrgent = daysLabel == 'Today!' || daysLabel == 'Tomorrow';

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_iconForType(type), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event['title'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _slate)),
            const SizedBox(height: 2),
            Text(event['date'] as String? ?? '', style: const TextStyle(fontSize: 12, color: _gray)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgent ? color.withOpacity(0.12) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(daysLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isUrgent ? color : _gray)),
          ),
        ]),
      ),
      if (!isLast) const Divider(height: 1, indent: 68),
    ]);
  }
}

// ─── Insight / Upgrade Cards ─────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_dark, _darkMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_purple, _indigo]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('AI INSIGHT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 10),
          const Text(
            'Today\'s Tip',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Check in with your partner today — even a quick "thinking of you" message strengthens your bond.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.5),
          ),
        ])),
        const SizedBox(width: 12),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.auto_awesome, color: Color(0xFFfbbf24), size: 24),
        ),
      ]),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_purple, _indigo, _dark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _purple.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('✦ Unlock Premium', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('AI Coach, Pattern Detection & Weekly Reports', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, height: 1.4)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Text('Upgrade — ₹199/mo', style: TextStyle(color: _purple, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ])),
          const SizedBox(width: 8),
          const Text('🚀', style: TextStyle(fontSize: 40)),
        ]),
      ),
    );
  }
}

// ─── RELATIONSHIPS TAB ───────────────────────────────────────────────────────
class _RelationshipsTab extends StatelessWidget {
  final List<Relationship> relationships;
  final bool loading;
  final int myId;
  final VoidCallback onRefresh;

  const _RelationshipsTab({required this.relationships, required this.loading, required this.myId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _rose,
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                alignment: Alignment.bottomLeft,
                child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your Bonds', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _slate, letterSpacing: -0.5)),
                  Text('${relationships.length} active connection${relationships.length != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 13, color: _gray)),
                ]),
              ),
            ),
            title: const Text('Bonds', style: TextStyle(color: _slate, fontWeight: FontWeight.w700)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateRelationshipScreen()));
                    if (ok == true) onRefresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: _roseLight, borderRadius: BorderRadius.circular(20)),
                    child: const Text('+ Add', style: TextStyle(color: _rose, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),

          if (loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _rose)))
          else if (relationships.isEmpty)
            SliverFillRemaining(
              child: _EmptyRelationships(onAdd: () async {
                final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateRelationshipScreen()));
                if (ok == true) onRefresh();
              }),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _RelCard(
                    rel: relationships[i],
                    myId: myId,
                    onTap: () async {
                      await Navigator.push(ctx, MaterialPageRoute(
                        builder: (_) => RelationshipDetailScreen(relationship: relationships[i], myId: myId),
                      ));
                      onRefresh();
                    },
                  ),
                  childCount: relationships.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RelCard extends StatefulWidget {
  final Relationship rel;
  final int myId;
  final VoidCallback onTap;
  const _RelCard({required this.rel, required this.myId, required this.onTap});

  @override
  State<_RelCard> createState() => _RelCardState();
}

class _RelCardState extends State<_RelCard> {
  HealthScore? _health;

  @override
  void initState() {
    super.initState();
    ApiService.getHealthScore(widget.rel.id).then((h) { if (mounted) setState(() => _health = h); });
  }

  Color get _scoreColor => switch (_health?.color ?? '') {
    'green' => const Color(0xFF22c55e),
    'yellow' => const Color(0xFFeab308),
    'red' => const Color(0xFFef4444),
    _ => const Color(0xFF3b82f6),
  };

  List<Color> get _gradient => _relGradients[widget.rel.relationshipType] ?? [_rose, _roseMid];

  @override
  Widget build(BuildContext context) {
    final other = widget.rel.otherUser(widget.myId);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 6,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _gradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            ),
          ),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 24,
            backgroundColor: _gradient.first.withOpacity(0.12),
            child: Text(other.initials, style: TextStyle(color: _gradient.first, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(other.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _slate)),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _gradient.first.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.rel.typeLabel, style: TextStyle(fontSize: 11, color: _gradient.first, fontWeight: FontWeight.w600)),
              ),
            ]),
          ])),
          if (_health != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${_health!.overall}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _scoreColor, height: 1)),
              Text(_health!.label, style: TextStyle(fontSize: 10, color: _scoreColor, fontWeight: FontWeight.w600)),
            ])
          else
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: _rose)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, color: _gray.withOpacity(0.5), size: 14),
          const SizedBox(width: 16),
        ]),
      ),
    );
  }
}

// ─── PROFILE TAB ─────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final dynamic user;
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AuthProvider>().isPremium;
    final initial = user?.firstName?.isNotEmpty == true ? user!.firstName[0].toUpperCase() : '?';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: _dark,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_dark, _darkMid, Color(0xFF24243e)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Stack(children: [
                Positioned(top: -40, right: -30,
                  child: Container(width: 200, height: 200,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _rose.withOpacity(0.05)))),
                SafeArea(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 40),
                    Stack(children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_rose, _roseMid]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _rose.withOpacity(0.4), blurRadius: 16)],
                        ),
                        child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
                      ),
                      if (isPremium)
                        Positioned(bottom: 0, right: 0,
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_purple, _indigo]),
                              shape: BoxShape.circle,
                              border: Border.all(color: _dark, width: 2),
                            ),
                            child: const Center(child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 9))),
                          )),
                    ]),
                    const SizedBox(height: 12),
                    Text(user?.fullName ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
                    const SizedBox(height: 12),
                    isPremium
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_purple, _indigo]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('✦ Premium Member', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final upgraded = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                              if (upgraded == true) context.read<AuthProvider>().refreshPremiumStatus();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [_purple, _indigo]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: _purple.withOpacity(0.4), blurRadius: 8)],
                              ),
                              child: const Text('Upgrade to Premium ✦', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ),
                  ]),
                ),
              ]),
            ),
          ),
          title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverToBoxAdapter(
            child: Column(children: [
              _SettingsSection(title: 'Account', tiles: [
                _SettingsTile(icon: Icons.workspace_premium_rounded, label: isPremium ? 'Premium Plan — Active' : 'Get HarmonyAI Premium',
                    color: _purple, onTap: () async {
                  final upgraded = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                  if (upgraded == true) context.read<AuthProvider>().refreshPremiumStatus();
                }),
                _SettingsTile(icon: Icons.person_outline_rounded, label: 'Edit Profile', color: _indigo, onTap: () {}),
                _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', color: const Color(0xFFf97316), onTap: () {}),
              ]),
              const SizedBox(height: 12),
              _SettingsSection(title: 'App', tiles: [
                _SettingsTile(icon: Icons.lock_outline_rounded, label: 'Privacy & Security', color: const Color(0xFF059669), onTap: () {}),
                _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help & Support', color: const Color(0xFF0891b2), onTap: () {}),
                _SettingsTile(icon: Icons.info_outline_rounded, label: 'About HarmonyAI', color: _gray, onTap: () {}),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFef4444)),
                  label: const Text('Sign Out', style: TextStyle(color: Color(0xFFef4444), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFfecaca)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: const Color(0xFFFEF2F2),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsTile> tiles;
  const _SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _gray, letterSpacing: 0.8)),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: tiles.asMap().entries.map((e) {
            final isLast = e.key == tiles.length - 1;
            return Column(children: [
              e.value,
              if (!isLast) const Divider(height: 1, indent: 56),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _slate)),
      trailing: Icon(Icons.chevron_right_rounded, color: _gray.withOpacity(0.5), size: 20),
      onTap: onTap,
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
class _EmptyRelationships extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyRelationships({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: _roseLight, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.favorite_rounded, color: _rose, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('No connections yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _slate)),
          const SizedBox(height: 8),
          const Text('Add your first bond to start building healthier relationships.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _gray, height: 1.5)),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: _rose,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Add First Bond', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, style: const TextStyle(color: _gray, fontSize: 14)));
  }
}
