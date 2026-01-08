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
  final List<String> likes; // ✅ NEW FIELD

  CrowdPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.imageUrl,
    required this.timestamp,
    required this.targetAmount,
    required this.raisedAmount,
    required this.likes, // ✅ REQUIRED
  });

  /// Convert to Firestore
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'text': text,
        'imageUrl': imageUrl,
        'timestamp': timestamp,
        'targetAmount': targetAmount,
        'raisedAmount': raisedAmount,
        'likes': likes, // ✅ SAVE LIKES
      };

  /// Read from Firestore
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
      likes: List<String>.from(json['likes'] ?? []), // ✅ SAFE READ
    );
  }

  /// Helper: check if user liked post
  bool isLikedBy(String uid) {
    return likes.contains(uid);
  }

  /// Helper: like count
  int get likeCount => likes.length;
}
