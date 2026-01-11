class AppUser {
  final String uid;
  final String email;
  final String username;

  // ROLE SYSTEM
  final String userType; // "Pind" or "User"

  // PHONE + LOCATION
  final String phoneNumber;
  final String city;
  final String town;

  // LOCATION FIELDS
  final String panchayatId;
  final String blockName;

  // ROLE FLAGS
  final bool isAdmin;      // Pind admin
  final bool isDeveloper;  // Tech / bulk uploads
  final bool isDC;         // 🔥 DC Office (Superuser)

  // PHONE VERIFICATION
  final bool isPhoneVerified;

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
    this.panchayatId = '',
    this.blockName = '',
    this.isAdmin = false,
    this.isDeveloper = false,
    this.isDC = false, // ✅ DEFAULT FALSE
    this.isPhoneVerified = false,
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
        'panchayatId': panchayatId,
        'blockName': blockName,
        'isAdmin': isAdmin,
        'isDeveloper': isDeveloper,
        'isDC': isDC,
        'isPhoneVerified': isPhoneVerified,
        'followers': followers,
        'following': following,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      userType: json['userType'] ?? 'User',
      phoneNumber: json['phoneNumber'] ?? '',
      city: json['city'] ?? '',
      town: json['town'] ?? '',
      panchayatId: json['panchayatId'] ?? '',
      blockName: json['blockName'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      isDeveloper: json['isDeveloper'] ?? false,
      isDC: json['isDC'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
    );
  }
}
