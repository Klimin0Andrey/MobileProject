import 'dart:async';
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/services/database.dart';

class AddressProvider with ChangeNotifier {
  List<DeliveryAddress> _addresses = [];
  DeliveryAddress? _selectedAddress; // ✅ НОВОЕ: Хранит адрес, выбранный в текущей сессии
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

  // ✅ НОВАЯ ЛОГИКА: Возвращаем либо выбранный руками, либо дефолтный
  DeliveryAddress? get selectedAddress {
    if (_selectedAddress != null) return _selectedAddress;
    return defaultAddress;
  }

  DeliveryAddress? get defaultAddress => _addresses.isEmpty
      ? null
      : _addresses.firstWhere(
        (addr) => addr.isDefault,
    orElse: () => _addresses.first,
  );

  bool get hasAddresses => _addresses.isNotEmpty;

  // ✅ НОВЫЙ МЕТОД: Установка текущего адреса
  void setSelectedAddress(DeliveryAddress address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> _loadAddresses() async {
    try {
      _userDataSubscription = _databaseService.userData.listen(
            (userData) {
          _addresses = userData.addresses;

          // Если текущий выбранный адрес был удален, сбрасываем выбор
          if (_selectedAddress != null) {
            final exists = _addresses.any((addr) => addr.id == _selectedAddress!.id);
            if (!exists) {
              _selectedAddress = null;
            } else {
              // Обновляем данные (вдруг название поменялось)
              _selectedAddress = _addresses.firstWhere((addr) => addr.id == _selectedAddress!.id);
            }
          }

          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error in user data stream: $error');
        },
      );
    } catch (e) {
      debugPrint('Error loading addresses: $e');
      rethrow;
    }
  }

  // Добавление нового адреса
  Future<void> addAddress(DeliveryAddress newAddress) async {
    try {
      final bool shouldBeDefault = _addresses.isEmpty || newAddress.isDefault;

      final addressToAdd = shouldBeDefault
          ? newAddress.copyWith(isDefault: true)
          : newAddress;

      if (addressToAdd.isDefault) {
        _addresses = _addresses
            .map((addr) => addr.copyWith(isDefault: false))
            .toList();
      }

      _addresses.add(addressToAdd);
      await _saveAddresses();

      // Если это первый адрес, сразу делаем его выбранным
      if (_addresses.length == 1) {
        _selectedAddress = addressToAdd;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding address: $e');
      rethrow;
    }
  }

  // Обновление адреса
  Future<void> updateAddress(
      String addressId,
      DeliveryAddress updatedAddress,
      ) async {
    try {
      final index = _addresses.indexWhere((addr) => addr.id == addressId);
      if (index != -1) {
        if (updatedAddress.isDefault && !_addresses[index].isDefault) {
          _addresses = _addresses
              .map((addr) => addr.copyWith(isDefault: false))
              .toList();
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
      final addressToRemove = _addresses.firstWhere(
            (addr) => addr.id == addressId,
      );
      final wasDefault = addressToRemove.isDefault;

      _addresses.removeWhere((addr) => addr.id == addressId);

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
      await _databaseService.updateUserAddresses(_addresses);
      debugPrint(
        '💾 Saved ${_addresses.length} addresses to database for user $uid',
      );
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

  // Загрузка тестовых данных
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
    await _saveAddresses();
    notifyListeners();
  }
}