import 'dart:async';
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/services/database.dart';

class AddressProvider with ChangeNotifier {
  List<DeliveryAddress> _addresses = [];
  final DatabaseService _databaseService;
  final String uid;

  StreamSubscription? _userDataSubscription;

  AddressProvider({required this.uid})
      : _databaseService = DatabaseService(uid: uid) {
    _loadAddresses();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  List<DeliveryAddress> get addresses => List.unmodifiable(_addresses);

  DeliveryAddress? get defaultAddress =>
      _addresses.firstWhere(
              (addr) => addr.isDefault,
          orElse: () => _addresses.isNotEmpty ? _addresses.first : DeliveryAddress(
            id: '',
            title: '',
            address: '',
            isDefault: false,
            createdAt: DateTime.now(),
          )
      );

  bool get hasAddresses => _addresses.isNotEmpty;

  Future<void> _loadAddresses() async {
    try {
      // ✅ РЕАЛЬНАЯ ЗАГРУЗКА ИЗ DATABASE SERVICE
      _userDataSubscription = _databaseService.userData.listen((userData) {
        _addresses = userData.addresses;
        notifyListeners();
      }, onError: (error) {
        debugPrint('Error in user data stream: $error');
      });
    } catch (e) {
      debugPrint('Error loading addresses: $e');
      rethrow;
    }
  }

  // Добавление нового адреса
  Future<void> addAddress(DeliveryAddress newAddress) async {
    try {
      // Если это первый адрес, делаем его default
      final bool shouldBeDefault = _addresses.isEmpty || newAddress.isDefault;

      final addressToAdd = shouldBeDefault
          ? newAddress.copyWith(isDefault: true)
          : newAddress;

      // Если новый адрес - default, сбрасываем у остальных
      if (addressToAdd.isDefault) {
        _addresses = _addresses.map((addr) => addr.copyWith(isDefault: false)).toList();
      }

      _addresses.add(addressToAdd);
      await _saveAddresses();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding address: $e');
      rethrow;
    }
  }

  // Обновление адреса
  Future<void> updateAddress(String addressId, DeliveryAddress updatedAddress) async {
    try {
      final index = _addresses.indexWhere((addr) => addr.id == addressId);
      if (index != -1) {
        // Если адрес стал default, сбрасываем у остальных
        if (updatedAddress.isDefault && !_addresses[index].isDefault) {
          _addresses = _addresses.map((addr) => addr.copyWith(isDefault: false)).toList();
        }

        _addresses[index] = updatedAddress;
        await _saveAddresses();
        notifyListeners();
      } else {
        throw Exception('Address with id $addressId not found');
      }
    } catch (e) {
      debugPrint('Error updating address: $e');
      rethrow;
    }
  }

  // Удаление адреса
  Future<void> removeAddress(String addressId) async {
    try {
      final addressToRemove = _addresses.firstWhere((addr) => addr.id == addressId);
      final wasDefault = addressToRemove.isDefault;

      _addresses.removeWhere((addr) => addr.id == addressId);

      // Если удалили default адрес и есть другие адреса, назначаем первый как default
      if (wasDefault && _addresses.isNotEmpty) {
        _addresses[0] = _addresses[0].copyWith(isDefault: true);
      }

      await _saveAddresses();
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing address: $e');
      rethrow;
    }
  }

  // Установка адреса по умолчанию
  Future<void> setDefaultAddress(String addressId) async {
    try {
      final index = _addresses.indexWhere((addr) => addr.id == addressId);
      if (index != -1) {
        _addresses = _addresses.map((addr) {
          return addr.copyWith(isDefault: addr.id == addressId);
        }).toList();

        await _saveAddresses();
        notifyListeners();
      } else {
        throw Exception('Address with id $addressId not found');
      }
    } catch (e) {
      debugPrint('Error setting default address: $e');
      rethrow;
    }
  }

  // Получение адреса по ID
  DeliveryAddress? getAddressById(String addressId) {
    try {
      return _addresses.firstWhere((addr) => addr.id == addressId);
    } catch (e) {
      return null;
    }
  }

  // Сохранение адресов в базу
  Future<void> _saveAddresses() async {
    try {
      // ✅ РЕАЛЬНОЕ СОХРАНЕНИЕ В DATABASE SERVICE
      await _databaseService.updateUserAddresses(_addresses);
      debugPrint('💾 Saved ${_addresses.length} addresses to database for user $uid');
    } catch (e) {
      debugPrint('Error saving addresses: $e');
      rethrow;
    }
  }

  // Очистка всех адресов
  Future<void> clearAddresses() async {
    _addresses.clear();
    await _saveAddresses();
    notifyListeners();
  }

  // Загрузка тестовых данных (для разработки)
  Future<void> loadMockAddresses() async {
    _addresses = [
      DeliveryAddress(
        id: '1',
        title: 'Дом',
        address: 'ул. Примерная, д. 10',
        apartment: '25',
        entrance: '2',
        floor: '5',
        intercom: '125',
        isDefault: true,
        lat: 55.7558,
        lng: 37.6173,
        createdAt: DateTime.now(),
      ),
      DeliveryAddress(
        id: '2',
        title: 'Работа',
        address: 'ул. Рабочая, д. 15',
        apartment: '101',
        isDefault: false,
        lat: 55.7517,
        lng: 37.6178,
        createdAt: DateTime.now(),
      ),
    ];
    await _saveAddresses(); // ✅ Сохраняем тестовые данные в БД
    notifyListeners();
  }


  void _addSampleAddresses() {
    _addresses = [
      DeliveryAddress.create(
        title: 'Дом',
        address: 'ул. Пушкина, д. 15',
        apartment: '25',
        entrance: '3',
        floor: '5',
        intercom: '124',
        comment: 'После 19:00',
        isDefault: true,
      ),
      DeliveryAddress.create(
        title: 'Работа',
        address: 'пр. Ленина, д. 42, офис 305',
        apartment: '305',
        comment: 'С 9:00 до 18:00',
        isDefault: false,
      ),
    ];
    notifyListeners();
  }

}