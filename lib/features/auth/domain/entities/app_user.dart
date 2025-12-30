class AppUser {
  final String uid;
  final String email;
  final bool isAdmin; // NEW: True = Village Head, False = Normal User

  AppUser({
    required this.uid, 
    required this.email,
    this.isAdmin = false, // Default is normal user
  });

  Map<String, dynamic> toJson() => {
    'uid': uid, 
    'email': email,
    'isAdmin': isAdmin,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'], 
      email: json['email'],
      isAdmin: json['isAdmin'] ?? false,
    );
  }
}