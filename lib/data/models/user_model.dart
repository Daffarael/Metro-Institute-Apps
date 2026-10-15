/// UserModel — represents authenticated Mentee user in Metro Institute.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final String role;
  final String? selectedField;
  final bool skillTestDone;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final String badgeLevel;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.bio,
    this.role = 'MENTEE',
    this.selectedField,
    this.skillTestDone = false,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badgeLevel = 'METRO_ROOKIE',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Mentee',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      role: json['role'] as String? ?? 'MENTEE',
      selectedField: json['selectedField'] as String?,
      skillTestDone: json['skillTestDone'] as bool? ?? false,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      badgeLevel: json['badgeLevel'] as String? ?? 'METRO_ROOKIE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
      'role': role,
      'selectedField': selectedField,
      'skillTestDone': skillTestDone,
      'totalXp': totalXp,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'badgeLevel': badgeLevel,
    };
  }
}
