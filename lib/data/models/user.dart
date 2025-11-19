// lib/data/models/user.dart

import 'package:linux_test2/data/models/address.dart';
import 'package:equatable/equatable.dart';

// --- ЕДИНСТВЕННАЯ МОДЕЛЬ ПОЛЬЗОВАТЕЛЯ ---
class AppUser extends Equatable {
  final String uid;
  final String email;
  final String role;
  final String name;
  final String phone;
  final List<DeliveryAddress> addresses;
  final List<String> favorites;
  final String? avatarUrl;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
    required this.addresses,
    required this.favorites,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    role,
    name,
    phone,
    addresses,
    favorites,
    avatarUrl
  ];

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'phone': phone,
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'favorites': favorites,
      'avatarUrl': avatarUrl,
    };
  }

  // Этот метод теперь - единственный источник правды для создания AppUser из Firestore
  static AppUser fromMap(Map<String, dynamic> map) {
    List<DeliveryAddress> addressesList = [];
    final addressesData = map['addresses'];
    if (addressesData is List) {
      if (addressesData.isNotEmpty) {
        final firstItem = addressesData.first;
        if (firstItem is String) {
          // Обратная совместимость со старым форматом адресов
          addressesList = addressesData.map((addressString) {
            return DeliveryAddress(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Адрес',
              address: addressString,
              isDefault: addressesList.isEmpty,
              createdAt: DateTime.now(),
            );
          }).toList();
        } else if (firstItem is Map) {
          // Новый, правильный формат адресов
          addressesList = addressesData
              .map(
                (addressMap) => DeliveryAddress.fromMap(
                  Map<String, dynamic>.from(addressMap),
                ),
              )
              .toList();
        }
      }
    }

    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      addresses: addressesList,
      favorites: List<String>.from(map['favorites'] ?? []),
      avatarUrl: map['avatarUrl'],
    );
  }

  // --- ГЕТТЕРЫ И COPYWITH ---

  DeliveryAddress? get defaultAddress {
    try {
      // Ищем адрес, который явно помечен как isDefault: true
      return addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      // Если такого нет, возвращаем первый из списка или null, если список пуст
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? role,
    String? name,
    String? phone,
    List<DeliveryAddress>? addresses,
    List<String>? favorites,
    String? avatarUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addresses: addresses ?? this.addresses,
      favorites: favorites ?? this.favorites,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, name: $name, addresses: ${addresses.length})';
  }
}

// --- УТИЛИТАРНЫЕ МЕТОДЫ ---
extension AppUserUtils on AppUser {
  bool get isAdmin => role == 'admin';

  bool get isCourier => role == 'courier';

  bool get isCustomer => role == 'customer';

  bool get hasAddresses => addresses.isNotEmpty;

  String get initials {
    if (name.isNotEmpty) return name[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }
}

// --- СОЗДАНИЕ ПУСТОГО ПОЛЬЗОВАТЕЛЯ ---
class EmptyUser {
  static AppUser get appUser => AppUser(
    uid: '',
    email: '',
    role: 'customer',
    name: '',
    phone: '',
    addresses: [],
    favorites: [],
    avatarUrl: null,
  );
}
