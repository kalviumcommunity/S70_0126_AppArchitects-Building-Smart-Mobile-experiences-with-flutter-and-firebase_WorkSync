class TeamMember {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? avatarColor;

  TeamMember({
    this.id = '',
    required this.userId,
    required this.name,
    required this.email,
    this.role = 'Member',
    this.avatarColor,
  });

  factory TeamMember.fromMap(Map<String, dynamic> data, String id) {
    return TeamMember(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Member',
      avatarColor: data['avatarColor'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'avatarColor': avatarColor,
    };
  }
}
