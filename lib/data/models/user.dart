class AppUser {
  final String uid;
  final String email;
  final String role;
  final String name;
  final String phone;
  final List<String> addresses;
  final List<String> favorites;
  final String? avatarUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
    required this.addresses,
    required this.favorites,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'phone': phone,
      'addresses': addresses,
      'favorites': favorites,
      'avatarUrl': avatarUrl,
    };
  }

  static AppUser fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      addresses: List<String>.from(map['addresses'] ?? []),
      favorites: List<String>.from(map['favorites'] ?? []),
      avatarUrl: map['avatarUrl'],
    );
  }
}

class UserData {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final List<String> addresses;
  final List<String> favorites;
  final String? avatarUrl;

  UserData({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.addresses,
    required this.favorites,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'addresses': addresses,
      'favorites': favorites,
      'avatarUrl': avatarUrl,
    };
  }

  static UserData fromMap(Map<String, dynamic> map) {
    return UserData(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'customer',
      addresses: List<String>.from(map['addresses'] ?? []),
      favorites: List<String>.from(map['favorites'] ?? []),
      avatarUrl: map['avatarUrl'],
    );
  }
}