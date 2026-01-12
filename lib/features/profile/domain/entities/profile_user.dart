import '../../../../features/auth/domain/entities/app_user.dart';

class ProfileUser extends AppUser {
  final String bio;
  final String profileImageUrl;

  // FOLLOW SYSTEM (kept for UI stability)
  final List<String> followers;
  final List<String> following;

  ProfileUser({
    // ===== AppUser (SUPER) FIELDS =====
    required super.uid,
    required super.email,
    required super.username,
    required super.userType,
    required super.isAdmin,
    required super.isDC,
    required super.phoneNumber,
    required super.city,
    required super.town,
    required super.blockName,
    required super.panchayatId,

    // ===== Profile-specific =====
    required this.bio,
    required this.profileImageUrl,

    // ===== Follow system =====
    this.followers = const [],
    this.following = const [],
  });

  // ===============================
  // 🔁 COPY (USED BY ProfileCubit)
  ProfileUser copyWithProfile({
  String? bio,
  String? profileImageUrl,
}) {
  return ProfileUser(
    uid: uid,
    email: email,
    username: username,
    userType: userType,
    isAdmin: isAdmin,
    isDC: isDC,
    phoneNumber: phoneNumber,
    city: city,
    town: town,
    blockName: blockName,
    panchayatId: panchayatId,
    bio: bio ?? this.bio,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    followers: followers,
    following: following,
  );
}

  // ===============================
  // 🔄 TO SUPABASE
  // ===============================
  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'bio': bio,
      'profile_image_url': profileImageUrl,
    });
    return map;
  }

  // ===============================
  // 🔄 FROM SUPABASE
  // ===============================
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      uid: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      userType: json['user_type'] ?? 'Supporter',
      isAdmin: json['is_admin'] ?? false,
      isDC: json['is_dc'] ?? false,
      phoneNumber: json['phone_number'] ?? '',
      city: json['city'] ?? '',
      town: json['town'] ?? '',
      blockName: json['block_name'] ?? '',
      panchayatId: json['panchayat_id'] ?? '',
      bio: json['bio'] ?? '',
      profileImageUrl: json['profile_image_url'] ?? '',
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
    );
  }
}
