class AppUser {
  final String uid;
  final String email;
  final String username;

  // ROLE SYSTEM
  final String userType; // "Sarpanch" or "Supporter"

  // PHONE + LOCATION
  final String phoneNumber;
  final String city;
  final String town;

  // NEW LOCATION FIELDS
  final String panchayatId; // NEW
  final String blockName;   // NEW

  // OTP + ADMIN STATE
  final bool isPhoneVerified;
  final bool isAdmin;

  // FOLLOW SYSTEM
  final List<String> followers;
  final List<String> following;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.userType,
    this.phoneNumber = '',
    this.city = '',
    this.town = '',
    this.panchayatId = '', // NEW
    this.blockName = '',   // NEW
    this.isPhoneVerified = false,
    this.isAdmin = false,
    this.followers = const [],
    this.following = const [],
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'username': username,
        'userType': userType,
        'phoneNumber': phoneNumber,
        'city': city,
        'town': town,
        'panchayatId': panchayatId, // NEW
        'blockName': blockName,     // NEW
        'isPhoneVerified': isPhoneVerified,
        'isAdmin': isAdmin,
        'followers': followers,
        'following': following,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      userType: json['userType'] ?? 'Supporter',
      phoneNumber: json['phoneNumber'] ?? '',
      city: json['city'] ?? '',
      town: json['town'] ?? '',
      panchayatId: json['panchayatId'] ?? '', // NEW
      blockName: json['blockName'] ?? '',     // NEW
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
    );
  }
}
