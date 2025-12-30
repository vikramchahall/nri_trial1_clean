import 'package:cloud_firestore/cloud_firestore.dart';

class CrowdPost {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final String imageUrl;
  final DateTime timestamp;
  final double targetAmount;
  final double raisedAmount;

  CrowdPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.imageUrl,
    required this.timestamp,
    required this.targetAmount,
    required this.raisedAmount,
  });

  // Convert for Firestore
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'text': text,
        'imageUrl': imageUrl,
        'timestamp': timestamp,
        'targetAmount': targetAmount,
        'raisedAmount': raisedAmount,
      };

  // Read from Firestore
  factory CrowdPost.fromJson(Map<String, dynamic> json, String docId) {
    return CrowdPost(
      id: docId,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'User',
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      raisedAmount: (json['raisedAmount'] ?? 0).toDouble(),
    );
  }
}