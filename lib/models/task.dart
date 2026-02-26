import 'package:cloud_firestore/cloud_firestore.dart';

// This class defines the data structure for a Task
class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime dueDate;
  final String userId;

  Task({
    this.id = '',
    required this.title,
    required this.description,
    this.status = 'Pending',
    this.priority = 'Low',
    required this.dueDate,
    this.userId = '',
  });

  factory Task.fromMap(Map<String, dynamic> data, String id) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'Pending',
      priority: data['priority'] ?? 'Low',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': Timestamp.fromDate(dueDate),
      'userId': userId,
    };
  }
}
