class AppUser {
  final String uid;
  final String email;
  final String username;
  final String userType;
  final bool isAdmin;
  final bool isDC;

  // EXTRA PROFILE FIELDS
  final String phoneNumber;
  final String city;
  final String town;
  final String blockName;
  final String panchayatId;

  // 🔥 REQUIRED FOR FOLLOW SYSTEM
  final List<String> following;
  final List<String> followers;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.userType,
    required this.isAdmin,
    this.isDC = false,
    this.phoneNumber = '',
    this.city = '',
    this.town = '',
    this.blockName = '',
    this.panchayatId = '',

    // follow system
    this.following = const [],
    this.followers = const [],
  });

  // ===============================
  // 🔄 TO SUPABASE (INSERT / UPDATE)
  // ===============================
  Map<String, dynamic> toJson() => {
        'id': uid,
        'email': email,
        'username': username,
        'user_type': userType,
        'is_admin': isAdmin,
        'is_dc': isDC,
        'phone_number': phoneNumber,
        'city': city,
        'town': town,
        'block_name': blockName,
        'panchayat_id': panchayatId,
        // ❌ followers/following NOT stored here
      };

  // ===============================
  // 🔄 FROM SUPABASE (SELECT)
  // ===============================
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['id']?.toString() ?? '',
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

      // ✅ SAFE LIST PARSING (FROM JOIN / MANUAL MERGE)
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
  // 🔁 COPY WITH (OPTIONAL, SAFE)
  // ===============================
  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
    String? userType,
    bool? isAdmin,
    bool? isDC,
    String? phoneNumber,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      town: town ?? this.town,
      blockName: blockName ?? this.blockName,
      panchayatId: panchayatId ?? this.panchayatId,
      following: following ?? this.following,
      followers: followers ?? this.followers,
    );
  }
}
