import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/admin_users_service.dart';

class AdminUsersProvider with ChangeNotifier {
  final AdminUsersService _usersService = AdminUsersService();
  
  bool _isLoading = false;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Получить всех пользователей
  Stream<List<AppUser>> getAllUsers() {
    if (_searchQuery.isNotEmpty) {
      return _usersService.searchUsers(_searchQuery);
    }
    return _usersService.getAllUsers();
  }

  // Получить клиентов
  Stream<List<AppUser>> getCustomers() {
    if (_searchQuery.isNotEmpty) {
      return _usersService.searchUsers(_searchQuery)
          .map((users) => users.where((u) => u.isCustomer).toList());
    }
    return _usersService.getCustomers();
  }

  // Получить сотрудников
  Stream<List<AppUser>> getEmployees() {
    if (_searchQuery.isNotEmpty) {
      return _usersService.searchUsers(_searchQuery)
          .map((users) => users.where((u) => u.isAdmin || u.isCourier).toList());
    }
    return _usersService.getEmployees();
  }

  // Установить поисковый запрос
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Забанить/разбанить пользователя
  Future<void> banUser(String uid, bool isBanned) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _usersService.banUser(uid, isBanned);
    } catch (e) {
      debugPrint('Ошибка при бане пользователя: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Изменить роль пользователя
  Future<void> updateUserRole(String uid, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _usersService.updateUserRole(uid, role);
    } catch (e) {
      debugPrint('Ошибка при изменении роли: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Обновить данные пользователя
  Future<void> updateUser({
    required String uid,
    String? name,
    String? phone,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _usersService.updateUser(
        uid: uid,
        name: name,
        phone: phone,
        email: email,
      );
    } catch (e) {
      debugPrint('Ошибка при обновлении пользователя: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Получить количество заказов пользователя
  Future<int> getUserOrdersCount(String userId) async {
    return await _usersService.getUserOrdersCount(userId);
  }
}

