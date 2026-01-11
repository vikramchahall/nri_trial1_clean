class AppUser {
  final String uid;
  final String email;
  final String username;
  final String userType;
  final bool isAdmin;
  final bool isDC;

  // EXTRA FIELDS (needed to fix current UI + cubit errors)
  final String phoneNumber;
  final String city;
  final String town;
  final String blockName;
  final String panchayatId;

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
      };

  // ===============================
  // 🔄 FROM SUPABASE (SELECT)
  // ===============================
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
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
    );
  }
}
