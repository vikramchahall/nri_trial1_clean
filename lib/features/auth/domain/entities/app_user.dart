class AppUser {
  // ===============================
  // CORE IDENTITY
  // ===============================
  final String uid;
  final String email;
  final String username;
  final String userType;
  final bool isAdmin;
  final bool isDC;

  // ===============================
  // PROFILE
  // ===============================
  final String bio;
  final String profileImageUrl;
  final int imageVersion;

  // ===============================
  // EXTRA PROFILE FIELDS
  // ===============================
  final String phone;
  final String city;
  final String town;
  final String blockName;
  final String panchayatId;

  // ===============================
  // FOLLOW SYSTEM
  // ===============================
  final List<String> following;
  final List<String> followers;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.userType,
    required this.isAdmin,
    this.isDC = false,

    // profile
    this.bio = '',
    this.profileImageUrl = '',
    this.imageVersion = 0,

    // extra fields
    this.phone = '',
    this.city = '',
    this.town = '',
    this.blockName = '',
    this.panchayatId = '',

    // follow system
    this.following = const [],
    this.followers = const [],
  });

  // ===============================
  // 📤 TO SUPABASE (INSERT / UPDATE)
  // ===============================
  Map<String, dynamic> toJson() => {
        'id': uid,
        'email': email,
        'username': username,
        'user_type': userType,
        'is_admin': isAdmin,
        'is_dc': isDC,
        'bio': bio,
        'profile_image_url': profileImageUrl,
        'image_version': imageVersion,
        'phone': phone,
        'city': city,
        'town': town,
        'block_name': blockName,
        'panchayat_id': panchayatId,
        // ❌ followers/following NOT stored here
      };

  // ===============================
  // 📥 FROM SUPABASE (SELECT)
  // ===============================
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? '',
      isAdmin: json['is_admin'] == true,
      isDC: json['is_dc'] == true,

      bio: json['bio']?.toString() ?? '',
      profileImageUrl: json['profile_image_url']?.toString() ?? '',
      imageVersion: json['image_version'] ?? 0,

      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      town: json['town']?.toString() ?? '',
      blockName: json['block_name']?.toString() ?? '',
      panchayatId: json['panchayat_id']?.toString() ?? '',

      // ✅ SAFE LIST PARSING
      following: (json['following'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      followers: (json['followers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // ===============================
  // 🔁 COPY WITH
  // ===============================
  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
    String? userType,
    bool? isAdmin,
    bool? isDC,
    String? bio,
    String? profileImageUrl,
    int? imageVersion,
    String? phone,
    String? city,
    String? town,
    String? blockName,
    String? panchayatId,
    List<String>? following,
    List<String>? followers,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      userType: userType ?? this.userType,
      isAdmin: isAdmin ?? this.isAdmin,
      isDC: isDC ?? this.isDC,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      imageVersion: imageVersion ?? this.imageVersion,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      town: town ?? this.town,
      blockName: blockName ?? this.blockName,
      panchayatId: panchayatId ?? this.panchayatId,
      following: following ?? this.following,
      followers: followers ?? this.followers,
    );
  }
}
