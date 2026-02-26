// Client model: minimal fields with optional email and notes
class Client {
  final String id;
  final String userId;
  final String name;
  final String? email;
  final String? notes;

  Client({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'notes': notes,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map, String id) {
    return Client(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      notes: map['notes'],
    );
  }
}
