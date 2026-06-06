import 'user.dart';

class Relationship {
  final int id;
  final User creator;
  final User? partner;
  final String relationshipType;
  final String status;
  final String inviteToken;
  final String? inviteLink;
  final DateTime createdAt;

  Relationship({
    required this.id,
    required this.creator,
    this.partner,
    required this.relationshipType,
    required this.status,
    required this.inviteToken,
    this.inviteLink,
    required this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  String get typeLabel {
    const labels = {
      'couple': 'Couple',
      'parent_child': 'Parent / Child',
      'friends': 'Friends',
      'business': 'Business Partners',
    };
    return labels[relationshipType] ?? relationshipType;
  }

  User otherUser(int myId) => creator.id == myId ? (partner ?? creator) : creator;

  factory Relationship.fromJson(Map<String, dynamic> j) => Relationship(
        id: j['id'],
        creator: User.fromJson(j['creator']),
        partner: j['partner'] != null ? User.fromJson(j['partner']) : null,
        relationshipType: j['relationship_type'],
        status: j['status'],
        inviteToken: j['invite_token'],
        inviteLink: j['invite_link'],
        createdAt: DateTime.parse(j['created_at']),
      );
}

class HealthScore {
  final int overall;
  final int moodScore;
  final int connectionScore;
  final int conflictScore;
  final String label;
  final String color;

  HealthScore({
    required this.overall,
    required this.moodScore,
    required this.connectionScore,
    required this.conflictScore,
    required this.label,
    required this.color,
  });

  factory HealthScore.fromJson(Map<String, dynamic> j) => HealthScore(
        overall: j['overall'],
        moodScore: j['mood_score'],
        connectionScore: j['connection_score'],
        conflictScore: j['conflict_score'],
        label: j['label'],
        color: j['color'],
      );
}
