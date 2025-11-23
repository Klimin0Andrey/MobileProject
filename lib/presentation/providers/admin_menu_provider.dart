import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/data/models/dish.dart';
import 'package:linux_test2/services/admin_menu_service.dart';

class AdminMenuProvider with ChangeNotifier {
  final AdminMenuService _menuService = AdminMenuService();
  
  List<Restaurant> _restaurants = [];
  List<Dish> _dishes = [];
  Restaurant? _selectedRestaurant;
  bool _isLoading = false;

  List<Restaurant> get restaurants => _restaurants;
  List<Dish> get dishes => _dishes;
  Restaurant? get selectedRestaurant => _selectedRestaurant;
  bool get isLoading => _isLoading;

  // Загрузить все рестораны
  Stream<List<Restaurant>> getAllRestaurants() {
    return _menuService.getAllRestaurants();
  }

  // Загрузить блюда ресторана
  Stream<List<Dish>> getRestaurantDishes(String restaurantId) {
    return _menuService.getRestaurantDishes(restaurantId);
  }

  // Установить выбранный ресторан
  void setSelectedRestaurant(Restaurant? restaurant) {
    _selectedRestaurant = restaurant;
    _dishes = [];
    notifyListeners();
  }

  // Создать ресторан
  Future<void> createRestaurant({
    required String name,
    required String description,
    required String deliveryTime,
    required List<String> cuisineType,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _menuService.createRestaurant(
        name: name,
        description: description,
        deliveryTime: deliveryTime,
        cuisineType: cuisineType,
        imageUrl: imageUrl,
      );
    } catch (e) {
      debugPrint('Ошибка при создании ресторана: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Обновить ресторан
  Future<void> updateRestaurant({
    required String restaurantId,
    String? name,
    String? description,
    String? deliveryTime,
    List<String>? cuisineType,
    String? imageUrl,
    bool? isActive,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _menuService.updateRestaurant(
        restaurantId: restaurantId,
        name: name,
        description: description,
        deliveryTime: deliveryTime,
        cuisineType: cuisineType,
        imageUrl: imageUrl,
        isActive: isActive,
      );
    } catch (e) {
      debugPrint('Ошибка при обновлении ресторана: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Создать блюдо
  Future<void> createDish({
    required String restaurantId,
    required String name,
    required String description,
    required double price,
    required String category,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _menuService.createDish(
        restaurantId: restaurantId,
        name: name,
        description: description,
        price: price,
        category: category,
        imageUrl: imageUrl,
        isAvailable: isAvailable,
      );
    } catch (e) {
      debugPrint('Ошибка при создании блюда: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Обновить блюдо
  Future<void> updateDish({
    required String dishId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _menuService.updateDish(
        dishId: dishId,
        name: name,
        description: description,
        price: price,
        category: category,
        imageUrl: imageUrl,
        isAvailable: isAvailable,
      );
    } catch (e) {
      debugPrint('Ошибка при обновлении блюда: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Переключить доступность блюда
  Future<void> toggleDishAvailability(String dishId, bool isAvailable) async {
    try {
      await _menuService.toggleDishAvailability(dishId, isAvailable);
    } catch (e) {
      debugPrint('Ошибка при переключении доступности блюда: $e');
      rethrow;
    }
  }

  // Загрузить изображение ресторана
  Future<String?> uploadRestaurantImage(String imagePath, String restaurantId) async {
    try {
      final imageFile = XFile(imagePath);
      return await _menuService.uploadRestaurantImage(imageFile, restaurantId);
    } catch (e) {
      debugPrint('Ошибка при загрузке изображения ресторана: $e');
      return null;
    }
  }

  // Загрузить изображение блюда
  Future<String?> uploadDishImage(String imagePath, String dishId) async {
    try {
      final imageFile = XFile(imagePath);
      return await _menuService.uploadDishImage(imageFile, dishId);
    } catch (e) {
      debugPrint('Ошибка при загрузке изображения блюда: $e');
      return null;
    }
  }
}
