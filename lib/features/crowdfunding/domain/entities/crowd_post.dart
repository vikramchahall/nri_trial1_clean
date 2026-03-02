class CrowdPost {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final String text;
  final String imageUrl;
  final double targetAmount;
  final double raisedAmount;
  final DateTime timestamp;
  final List<String> likes;
  final int commentCount;
  final String phoneNumber; // ✅ NEW

  const CrowdPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.text,
    required this.imageUrl,
    required this.targetAmount,
    required this.raisedAmount,
    required this.timestamp,
    this.likes = const [],
    this.commentCount = 0,
    required this.phoneNumber, // ✅ NEW
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        'user_profile_image_url': userProfileImageUrl,
        'text': text,
        'image_url': imageUrl,
        'target_amount': targetAmount,
        'raised_amount': raisedAmount,
        'timestamp': timestamp.toIso8601String(),
        'likes': likes,
        'comment_count': commentCount,
        'phone_number': phoneNumber, // ✅ SAVE
      };

  factory CrowdPost.fromJson(Map<String, dynamic> json, String docId) {
    return CrowdPost(
      id: docId,
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'User',
      userProfileImageUrl: json['user_profile_image_url'],
      text: json['text'] ?? '',
      imageUrl: json['image_url'] ?? '',
      targetAmount: (json['target_amount'] ?? 0).toDouble(),
      raisedAmount: (json['raised_amount'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      likes: List<String>.from(json['likes'] ?? []),
      commentCount: json['comment_count'] ?? 0,
      phoneNumber: json['phone_number'] ?? '', // ✅ READ
    );
  }

  CrowdPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImageUrl,
    String? text,
    String? imageUrl,
    double? targetAmount,
    double? raisedAmount,
    DateTime? timestamp,
    List<String>? likes,
    int? commentCount,
    String? phoneNumber, // ✅ NEW
  }) {
    return CrowdPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      targetAmount: targetAmount ?? this.targetAmount,
      raisedAmount: raisedAmount ?? this.raisedAmount,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      phoneNumber: phoneNumber ?? this.phoneNumber, // ✅ COPY
    );
  }

  int get likeCount => likes.length;
  bool isLikedBy(String uid) => likes.contains(uid);
}