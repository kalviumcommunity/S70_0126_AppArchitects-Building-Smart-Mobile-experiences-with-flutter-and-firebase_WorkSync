import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String userId;
  final String clientName;
  final double amount;
  final String status; // 'pending', 'completed'
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.userId,
    required this.clientName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clientName': clientName,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      userId: map['userId'] ?? '',
      clientName: map['clientName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
