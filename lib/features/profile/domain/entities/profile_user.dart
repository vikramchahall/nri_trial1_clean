import 'package:nri_trial1_clean/features/auth/domain/entities/app_user.dart';

class ProfileUser extends AppUser {
  final String name;
  final String bio;
  final String profileImageUrl;

  ProfileUser({
    required super.uid,
    required super.email,
    required super.isAdmin,
    required this.name,
    required this.bio,
    required this.profileImageUrl,
  });

  // Update profile info helper
  ProfileUser copyWith({String? newBio, String? newProfileImageUrl, String? newName}) {
    return ProfileUser(
      uid: uid,
      email: email,
      isAdmin: isAdmin,
      name: newName ?? name,
      bio: newBio ?? bio,
      profileImageUrl: newProfileImageUrl ?? profileImageUrl,
    );
  }

  // Convert for Firestore
  @override
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'isAdmin': isAdmin,
      'name': name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Read from Firestore
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }
}