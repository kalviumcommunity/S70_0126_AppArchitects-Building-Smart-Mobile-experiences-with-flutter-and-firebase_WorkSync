import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String type; // 'invite'
  final String title;
  final String body;
  final String status; // 'pending', 'accepted', 'declined'
  final String? projectId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.title,
    required this.body,
    required this.status,
    this.projectId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'title': title,
      'body': body,
      'status': status,
      'projectId': projectId,
      'createdAt': createdAt,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      recipientId: map['recipientId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      type: map['type'] ?? 'invite',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      status: map['status'] ?? 'pending',
      projectId: map['projectId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
