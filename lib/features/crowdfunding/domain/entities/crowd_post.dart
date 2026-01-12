class CrowdPost {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final String imageUrl;
  final double targetAmount;
  final double raisedAmount;
  final DateTime timestamp;
  final List<String> likes;

  CrowdPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.imageUrl,
    required this.targetAmount,
    required this.raisedAmount,
    required this.timestamp,
    this.likes = const [],
  });

  // ===============================
  // 🔄 TO SUPABASE (INSERT / UPDATE)
  // ===============================
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        'text': text,
        'image_url': imageUrl,
        'target_amount': targetAmount,
        'raised_amount': raisedAmount,
        'timestamp': timestamp.toIso8601String(),
      };

  // ===============================
  // 🔄 FROM SUPABASE (SELECT)
  // ===============================
  factory CrowdPost.fromJson(Map<String, dynamic> json, String docId) {
    return CrowdPost(
      id: docId,
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'User',
      text: json['text'] ?? '',
      imageUrl: json['image_url'] ?? '',
      targetAmount: (json['target_amount'] ?? 0).toDouble(),
      raisedAmount: (json['raised_amount'] ?? 0).toDouble(),
      // Supabase returns timestamps as ISO 8601 strings
      timestamp: DateTime.parse(json['timestamp']),
      likes: List<String>.from(json['likes'] ?? []),
    );
  }

  // ===============================
  // 🧠 HELPERS (UI SAFE)
  // ===============================
  int get likeCount => likes.length;

  bool isLikedBy(String uid) => likes.contains(uid);
}
