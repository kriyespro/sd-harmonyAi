class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isPremium;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.isPremium = false,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        email: j['email'],
        firstName: j['first_name'],
        lastName: j['last_name'] ?? '',
        isPremium: j['is_premium'] as bool? ?? false,
      );

  User copyWith({bool? isPremium}) => User(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        isPremium: isPremium ?? this.isPremium,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'is_premium': isPremium,
      };
}
