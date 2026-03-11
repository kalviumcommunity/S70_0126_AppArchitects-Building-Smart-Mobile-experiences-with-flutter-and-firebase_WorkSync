import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String status; // 'active', 'completed', 'on hold'
  final DateTime createdAt;
  final List<String> collaborators;

  Project({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.status,
    required this.createdAt,
    this.collaborators = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'status': status,
      'createdAt': createdAt,
      'collaborators': collaborators,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map, String id) {
    return Project(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      collaborators: List<String>.from(map['collaborators'] ?? []),
    );
  }
}
