class UserProfile {
  final int id;
  final String username;
  final String email;
  final String role;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['profile']?['role'] as String? ?? 'customer',
    );
  }
}
