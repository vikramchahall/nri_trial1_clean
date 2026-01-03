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
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
    );
  }
}
