import 'package:linux_test2/data/models/address.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final String name;
  final String phone;
  final List<DeliveryAddress> addresses;
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
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'favorites': favorites,
      'avatarUrl': avatarUrl,
    };
  }

  static AppUser fromMap(Map<String, dynamic> map) {
    // Обработка адресов с обратной совместимостью
    List<DeliveryAddress> addressesList = [];

    final addressesData = map['addresses'];
    if (addressesData is List) {
      if (addressesData.isNotEmpty) {
        // Проверяем тип данных в списке
        final firstItem = addressesData.first;
        if (firstItem is String) {
          // Старый формат: List<String> - преобразуем в DeliveryAddress
          addressesList = addressesData.map((addressString) {
            return DeliveryAddress(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Адрес',
              address: addressString,
              isDefault: addressesList.isEmpty, // первый адрес по умолчанию
              createdAt: DateTime.now(),
            );
          }).toList();
        } else if (firstItem is Map) {
          // Новый формат: List<Map> - преобразуем в DeliveryAddress
          addressesList = addressesData.map((addressMap) {
            return DeliveryAddress.fromMap(Map<String, dynamic>.from(addressMap));
          }).toList();
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

  // Получение адреса по умолчанию
  DeliveryAddress? get defaultAddress {
    try {
      return addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  // Для обратной совместимости со старым кодом
  List<String> get addressStrings => addresses.map((addr) => addr.address).toList();

  // Обновление адресов
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

  // Обновление только адресов
  AppUser copyWithAddresses(List<DeliveryAddress> newAddresses) {
    return AppUser(
      uid: uid,
      email: email,
      role: role,
      name: name,
      phone: phone,
      addresses: newAddresses,
      favorites: favorites,
      avatarUrl: avatarUrl,
    );
  }

  // Добавление нового адреса
  AppUser addAddress(DeliveryAddress newAddress) {
    final updatedAddresses = List<DeliveryAddress>.from(addresses);
    updatedAddresses.add(newAddress);
    return copyWith(addresses: updatedAddresses);
  }

  // Удаление адреса по ID
  AppUser removeAddress(String addressId) {
    final updatedAddresses = addresses.where((addr) => addr.id != addressId).toList();
    return copyWith(addresses: updatedAddresses);
  }

  // Обновление конкретного адреса
  AppUser updateAddress(String addressId, DeliveryAddress updatedAddress) {
    final updatedAddresses = addresses.map((addr) {
      return addr.id == addressId ? updatedAddress : addr;
    }).toList();
    return copyWith(addresses: updatedAddresses);
  }

  // Установка адреса по умолчанию
  AppUser setDefaultAddress(String addressId) {
    final updatedAddresses = addresses.map((addr) {
      return addr.copyWith(isDefault: addr.id == addressId);
    }).toList();
    return copyWith(addresses: updatedAddresses);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.uid == uid &&
        other.email == email &&
        other.role == role &&
        other.name == name &&
        other.phone == phone &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
    email.hashCode ^
    role.hashCode ^
    name.hashCode ^
    phone.hashCode ^
    avatarUrl.hashCode;
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, name: $name, role: $role, addresses: ${addresses.length})';
  }
}

class UserData {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final List<DeliveryAddress> addresses;
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
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'favorites': favorites,
      'avatarUrl': avatarUrl,
    };
  }

  static UserData fromMap(Map<String, dynamic> map) {
    // Обработка адресов с обратной совместимостью
    List<DeliveryAddress> addressesList = [];

    final addressesData = map['addresses'];
    if (addressesData is List) {
      if (addressesData.isNotEmpty) {
        final firstItem = addressesData.first;
        if (firstItem is String) {
          // Старый формат: List<String> - преобразуем в DeliveryAddress
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
          // Новый формат: List<Map> - преобразуем в DeliveryAddress
          addressesList = addressesData.map((addressMap) {
            return DeliveryAddress.fromMap(Map<String, dynamic>.from(addressMap));
          }).toList();
        }
      }
    }

    return UserData(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'customer',
      addresses: addressesList,
      favorites: List<String>.from(map['favorites'] ?? []),
      avatarUrl: map['avatarUrl'],
    );
  }

  // Получение адреса по умолчанию
  DeliveryAddress? get defaultAddress {
    try {
      return addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  // Для обратной совместимости со старым кодом
  List<String> get addressStrings => addresses.map((addr) => addr.address).toList();

  // Обновление данных
  UserData copyWith({
    String? uid,
    String? name,
    String? phone,
    String? role,
    List<DeliveryAddress>? addresses,
    List<String>? favorites,
    String? avatarUrl,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      addresses: addresses ?? this.addresses,
      favorites: favorites ?? this.favorites,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  // Добавление нового адреса
  UserData addAddress(DeliveryAddress newAddress) {
    final updatedAddresses = List<DeliveryAddress>.from(addresses);
    updatedAddresses.add(newAddress);
    return copyWith(addresses: updatedAddresses);
  }

  // Удаление адреса по ID
  UserData removeAddress(String addressId) {
    final updatedAddresses = addresses.where((addr) => addr.id != addressId).toList();
    return copyWith(addresses: updatedAddresses);
  }

  // Обновление конкретного адреса
  UserData updateAddress(String addressId, DeliveryAddress updatedAddress) {
    final updatedAddresses = addresses.map((addr) {
      return addr.id == addressId ? updatedAddress : addr;
    }).toList();
    return copyWith(addresses: updatedAddresses);
  }

  // Установка адреса по умолчанию
  UserData setDefaultAddress(String addressId) {
    final updatedAddresses = addresses.map((addr) {
      return addr.copyWith(isDefault: addr.id == addressId);
    }).toList();
    return copyWith(addresses: updatedAddresses);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.uid == uid &&
        other.name == name &&
        other.phone == phone &&
        other.role == role &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
    name.hashCode ^
    phone.hashCode ^
    role.hashCode ^
    avatarUrl.hashCode;
  }

  @override
  String toString() {
    return 'UserData(uid: $uid, name: $name, role: $role, addresses: ${addresses.length})';
  }
}

// Утилитарные методы для работы с пользователями
extension AppUserUtils on AppUser {
  // Проверка, является ли пользователь администратором
  bool get isAdmin => role == 'admin';

  // Проверка, является ли пользователь курьером
  bool get isCourier => role == 'courier';

  // Проверка, является ли пользователь клиентом
  bool get isCustomer => role == 'customer';

  // Получение инициалов для аватара
  String get initials {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // Проверка, есть ли у пользователя избранные товары
  bool get hasFavorites => favorites.isNotEmpty;

  // Проверка, есть ли у пользователя адреса
  bool get hasAddresses => addresses.isNotEmpty;
}

extension UserDataUtils on UserData {
  // Проверка, является ли пользователь администратором
  bool get isAdmin => role == 'admin';

  // Проверка, является ли пользователь курьером
  bool get isCourier => role == 'courier';

  // Проверка, является ли пользователь клиентом
  bool get isCustomer => role == 'customer';

  // Получение инициалов для аватара
  String get initials {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // Проверка, есть ли у пользователя избранные товары
  bool get hasFavorites => favorites.isNotEmpty;

  // Проверка, есть ли у пользователя адреса
  bool get hasAddresses => addresses.isNotEmpty;
}

// Создание пустого/дефолтного пользователя
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

  static UserData get userData => UserData(
    uid: '',
    name: '',
    phone: '',
    role: 'customer',
    addresses: [],
    favorites: [],
    avatarUrl: null,
  );
}