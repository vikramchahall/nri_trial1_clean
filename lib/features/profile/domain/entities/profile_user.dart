import '../../../../features/auth/domain/entities/app_user.dart';

class ProfileUser extends AppUser {
  final String bio;
  final String profileImageUrl;

  ProfileUser({
    // ✅ REQUIRED AppUser FIELDS
    required super.uid,
    required super.email,
    required super.username,
    required super.userType,
    required super.isAdmin,

    // OPTIONAL AppUser FIELDS
    super.phoneNumber,
    super.city,
    super.town,

    // FOLLOW SYSTEM
    super.followers,
    super.following,

    // PROFILE-SPECIFIC FIELDS
    required this.bio,
    required this.profileImageUrl,
  });

  // ✅ Required by ProfileCubit
  ProfileUser copyWith({
    String? newBio,
    String? newProfileImageUrl,
    String? newUsername,
  }) {
    return ProfileUser(
      uid: uid,
      email: email,
      username: newUsername ?? username,
      userType: userType,
      isAdmin: isAdmin,
      phoneNumber: phoneNumber,
      city: city,
      town: town,
      bio: newBio ?? bio,
      profileImageUrl: newProfileImageUrl ?? profileImageUrl,
      followers: followers,
      following: following,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'city': city,
      'town': town,
      'isAdmin': isAdmin,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'followers': followers,
      'following': following,
    };
  }

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      userType: json['userType'] ?? 'Supporter',
      isAdmin: json['isAdmin'] ?? false,
      phoneNumber: json['phoneNumber'] ?? '',
      city: json['city'] ?? '',
      town: json['town'] ?? '',
      bio: json['bio'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
    );
  }
}
