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

  // ===============================
  // 🔄 TO SUPABASE (INSERT)
  // ===============================
  Map<String, dynamic> toJson() => {
        'post_id': postId,
        'user_id': userId,
        'user_name': userName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  // ===============================
  // 🔄 FROM SUPABASE (SELECT)
  // ===============================
  factory Comment.fromJson(Map<String, dynamic> json, String id) {
    return Comment(
      id: id,
      postId: json['post_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'User',
      text: json['text'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
