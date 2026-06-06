class MoodEntry {
  final int id;
  final int relationship;
  final String mood;
  final String note;
  final DateTime date;

  MoodEntry({
    required this.id,
    required this.relationship,
    required this.mood,
    required this.note,
    required this.date,
  });

  String get emoji {
    const map = {
      'happy': '😊',
      'neutral': '😐',
      'sad': '😔',
      'angry': '😡',
      'stressed': '😰',
    };
    return map[mood] ?? '😐';
  }

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
        id: j['id'],
        relationship: j['relationship'],
        mood: j['mood'],
        note: j['note'] ?? '',
        date: DateTime.parse(j['date']),
      );
}

class ConflictEntry {
  final int id;
  final int relationship;
  final String category;
  final String description;
  final int severity;
  final bool resolved;
  final DateTime createdAt;

  ConflictEntry({
    required this.id,
    required this.relationship,
    required this.category,
    required this.description,
    required this.severity,
    required this.resolved,
    required this.createdAt,
  });

  factory ConflictEntry.fromJson(Map<String, dynamic> j) => ConflictEntry(
        id: j['id'],
        relationship: j['relationship'],
        category: j['category'],
        description: j['description'],
        severity: j['severity'],
        resolved: j['resolved'],
        createdAt: DateTime.parse(j['created_at']),
      );
}
