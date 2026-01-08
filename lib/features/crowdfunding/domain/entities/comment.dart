import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'text': text,
        'timestamp': timestamp,
      };

  factory Comment.fromJson(Map<String, dynamic> json, String docId) {
    return Comment(
      id: docId,
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'User',
      text: json['text'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}