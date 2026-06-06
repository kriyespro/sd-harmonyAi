import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/relationship.dart';
import '../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  final Relationship relationship;
  final int myId;

  const CalendarScreen({super.key, required this.relationship, required this.myId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _events = [];
  bool _loading = true;

  static const _typeEmoji = {
    'birthday': '🎂',
    'anniversary': '💍',
    'promise': '🤝',
    'vacation': '✈️',
    'family': '👨‍👩‍👧',
    'other': '📅',
  };
  static const _typeColor = {
    'birthday': Color(0xFFec4899),
    'anniversary': Color(0xFFf43f5e),
    'promise': Color(0xFF8b5cf6),
    'vacation': Color(0xFF0ea5e9),
    'family': Color(0xFF22c55e),
    'other': Color(0xFF6b7280),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getEvents(widget.relationship.id);
    setState(() {
      _events = data;
      _loading = false;
    });
  }

  List<dynamic> _eventsForDay(DateTime day) {
    return _events.where((e) {
      final d = DateTime.parse(e['date'] as String);
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  List<dynamic> _eventsForSelectedDay() {
    if (_selectedDay == null) return [];
    return _eventsForDay(_selectedDay!);
  }

  List<dynamic> get _upcomingEvents {
    final now = DateTime.now();
    final filtered = _events.where((e) {
      final d = DateTime.parse(e['date'] as String);
      return !d.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();
    filtered.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
    return filtered.take(10).toList();
  }

  bool _hasEvents(DateTime day) => _eventsForDay(day).isNotEmpty;

  void _prevMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  void _nextMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final other = widget.relationship.otherUser(widget.myId);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Events · ${other.fullName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEvent(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFf43f5e)))
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _CalendarCard(
                    focusedMonth: _focusedMonth,
                    selectedDay: _selectedDay,
                    hasEvents: _hasEvents,
                    onDayTap: (d) => setState(() => _selectedDay = _selectedDay == d ? null : d),
                    onPrev: _prevMonth,
                    onNext: _nextMonth,
                  )),
                  if (_selectedDay != null && _eventsForSelectedDay().isNotEmpty) ...[
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        DateFormat('EEEE, MMMM d').format(_selectedDay!),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      ),
                    )),
                    SliverList(delegate: SliverChildBuilderDelegate(
                      (_, i) => _EventTile(event: _eventsForSelectedDay()[i], typeEmoji: _typeEmoji, typeColor: _typeColor),
                      childCount: _eventsForSelectedDay().length,
                    )),
                  ],
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(children: [
                      const Text('Upcoming Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      const Spacer(),
                      Text('${_upcomingEvents.length} total', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    ]),
                  )),
                  _upcomingEvents.isEmpty
                      ? SliverToBoxAdapter(child: _EmptyState(onAdd: () => _showAddEvent(context)))
                      : SliverList(delegate: SliverChildBuilderDelegate(
                          (_, i) => _EventTile(event: _upcomingEvents[i], typeEmoji: _typeEmoji, typeColor: _typeColor, showDate: true),
                          childCount: _upcomingEvents.length,
                        )),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  void _showAddEvent(BuildContext context) {
    final categories = ['birthday', 'anniversary', 'promise', 'vacation', 'family', 'other'];
    String selectedType = categories[0];
    final titleCtrl = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    bool recurring = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Add Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 20),

              // Type selector
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final t = categories[i];
                    final selected = t == selectedType;
                    return GestureDetector(
                      onTap: () => setModal(() => selectedType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? (_typeColor[t] ?? const Color(0xFFf43f5e)).withOpacity(0.12) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected ? (_typeColor[t] ?? const Color(0xFFf43f5e)) : const Color(0xFFE5E7EB),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_typeEmoji[t] ?? '📅', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(t[0].toUpperCase() + t.substring(1),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: selected ? (_typeColor[t] ?? const Color(0xFFf43f5e)) : const Color(0xFF374151))),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: '${_typeEmoji[selectedType] ?? "📅"} e.g. Our Anniversary',
                ),
              ),
              const SizedBox(height: 14),

              // Date picker row
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2099),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFf43f5e))),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 10),
                    Text(DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              Row(children: [
                Switch(value: recurring, onChanged: (v) => setModal(() => recurring = v), activeColor: const Color(0xFFf43f5e)),
                const SizedBox(width: 8),
                const Text('Repeats yearly', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
              ]),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  await ApiService.addEvent(
                    widget.relationship.id,
                    selectedType,
                    titleCtrl.text.trim(),
                    selectedDate,
                    recurring: recurring,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                child: const Text('Add Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final bool Function(DateTime) hasEvents;
  final void Function(DateTime) onDayTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CalendarCard({
    required this.focusedMonth,
    required this.selectedDay,
    required this.hasEvents,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Month nav
          Row(children: [
            IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left, color: Color(0xFF374151))),
            Expanded(child: Text(
              DateFormat('MMMM yyyy').format(focusedMonth),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            )),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right, color: Color(0xFF374151))),
          ]),
          const SizedBox(height: 8),

          // Weekday headers
          Row(children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(
            child: Text(d, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
          )).toList()),
          const SizedBox(height: 8),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startWeekday) return const SizedBox();
              final day = DateTime(focusedMonth.year, focusedMonth.month, index - startWeekday + 1);
              final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
              final isSelected = selectedDay != null && day.year == selectedDay!.year && day.month == selectedDay!.month && day.day == selectedDay!.day;
              final hasEvent = hasEvents(day);

              return GestureDetector(
                onTap: () => onDayTap(day),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFf43f5e) : isToday ? const Color(0xFFfff1f2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${day.day}', style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? Colors.white : isToday ? const Color(0xFFf43f5e) : const Color(0xFF374151),
                      )),
                      if (hasEvent)
                        Container(
                          width: 4, height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFFf43f5e),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final dynamic event;
  final Map<String, String> typeEmoji;
  final Map<String, Color> typeColor;
  final bool showDate;

  const _EventTile({required this.event, required this.typeEmoji, required this.typeColor, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final type = event['event_type'] as String? ?? 'other';
    final color = typeColor[type] ?? const Color(0xFF6b7280);
    final date = DateTime.parse(event['date'] as String);
    final daysUntil = date.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(typeEmoji[type] ?? '📅', style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 2),
          Text(
            showDate ? DateFormat('MMM d, yyyy').format(date) : type[0].toUpperCase() + type.substring(1),
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ])),
        if (showDate && daysUntil >= 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: daysUntil == 0 ? const Color(0xFFf43f5e).withOpacity(0.1)
                   : daysUntil <= 7 ? const Color(0xFFfef3c7)
                   : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              daysUntil == 0 ? 'Today!'
                  : daysUntil == 1 ? 'Tomorrow'
                  : 'in $daysUntil days',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: daysUntil == 0 ? const Color(0xFFf43f5e)
                     : daysUntil <= 7 ? const Color(0xFFb45309)
                     : const Color(0xFF6B7280),
              ),
            ),
          ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        const Text('📅', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('No upcoming events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 6),
        const Text('Add birthdays, anniversaries & more.', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 20),
        SizedBox(width: 160, child: ElevatedButton(onPressed: onAdd, child: const Text('Add Event'))),
      ]),
    );
  }
}
