class AppUser {
  final String uid;
  final String email;
  final String role;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
  });
}

class UserProfile {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final List<String> addresses;
  final List<String> favorites;
  final String? avatarUrl;

  UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.addresses,
    required this.favorites,
    this.avatarUrl,
  });
}