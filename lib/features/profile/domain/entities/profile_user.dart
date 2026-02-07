class ProfileUser {
  final String uid;
  final String email;
  final String username;
  final String bio;
  final String profileImageUrl;
  final int imageVersion;
  final List<String> followers;
  final List<String> following;
  final String userType;
  final String city;
  final String town;
  final String block;
  final String panchayatId;
  final String phone;
  final bool isAdmin;
  final bool isDC; // ✅ ADDED

  ProfileUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.bio,
    required this.profileImageUrl,
    this.imageVersion = 0,
    this.followers = const [],
    this.following = const [],
    this.userType = '',
    this.city = '',
    this.town = '',
    this.block = '',
    this.panchayatId = '',
    this.phone = '',
    this.isAdmin = false,
    this.isDC = false, // ✅ ADDED
  });

  // ===============================
  // 📥 FROM JSON
  // ===============================
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      uid: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      profileImageUrl: json['profile_image_url']?.toString() ?? '',
      imageVersion: json['image_version'] ?? 0,
      followers: json['followers'] is List
          ? List<String>.from(json['followers'])
          : [],
      following: json['following'] is List
          ? List<String>.from(json['following'])
          : [],
      userType: json['user_type']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      town: json['town']?.toString() ?? '',
      block: json['block_name']?.toString() ?? '',
      panchayatId: json['panchayat_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isAdmin: json['is_admin'] == true,
      isDC: json['is_dc'] == true, // ✅ ADDED
    );
  }

  // ===============================
  // 📤 TO JSON
  // ===============================
  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'email': email,
      'username': username,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'image_version': imageVersion,
      'followers': followers,
      'following': following,
      'user_type': userType,
      'city': city,
      'town': town,
      'block_name': block,
      'panchayat_id': panchayatId,
      'phone': phone,
      'is_admin': isAdmin,
      'is_dc': isDC, // ✅ ADDED
    };
  }

  // ===============================
  // 🔄 COPY WITH (FOR PROFILE UPDATES)
  // ===============================
  ProfileUser copyWithProfile({
    String? bio,
    String? username,
    String? phone,
    String? city,
    String? town,
    String? block,
    String? panchayatId,
    String? profileImageUrl,
    int? imageVersion,
  }) {
    return ProfileUser(
      uid: uid,
      email: email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      town: town ?? this.town,
      block: block ?? this.block,
      panchayatId: panchayatId ?? this.panchayatId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      imageVersion: imageVersion ?? this.imageVersion,
      followers: followers,
      following: following,
      userType: userType,
      isAdmin: isAdmin,
      isDC: isDC, // ✅ ADDED
    );
  }

  // ===============================
  // 🔄 COPY WITH (FOR FOLLOW UPDATES)
  // ===============================
  ProfileUser copyWith({
    List<String>? followers,
    List<String>? following,
  }) {
    return ProfileUser(
      uid: uid,
      email: email,
      username: username,
      bio: bio,
      profileImageUrl: profileImageUrl,
      imageVersion: imageVersion,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      userType: userType,
      city: city,
      town: town,
      block: block,
      panchayatId: panchayatId,
      phone: phone,
      isAdmin: isAdmin,
      isDC: isDC, // ✅ ADDED
    );
  }
}