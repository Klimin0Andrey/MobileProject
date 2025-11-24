import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/services/restaurant_service.dart';
import 'package:linux_test2/data/models/dish.dart';

class RestaurantProvider with ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  String _selectedCuisine = 'Все';
  bool _isInitialized = false;

  List<Restaurant> get restaurants => _filteredRestaurants;

  List<Restaurant> get allRestaurants => _restaurants;

  String get selectedCuisine => _selectedCuisine;

  RestaurantProvider() {
    print('🔄 RestaurantProvider создан');
    _loadRestaurants();
  }

  void _loadRestaurants() {
    print('🔥 Начало загрузки ресторанов из Firestore...');

    // ✅ ИЗМЕНЕНО: Используем get() с Source.cache для первого чтения из кэша
    if (!_isInitialized) {
      _restaurantService.getRestaurants().first.then((restaurants) {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isInitialized = true;
        notifyListeners();
        print('✅ Загружено из кэша: ${restaurants.length} ресторанов');
      }).catchError((error) {
        print('❌ Ошибка загрузки из кэша: $error');
      });
    }

    // Затем слушаем изменения в реальном времени
    _restaurantService.getRestaurants().listen((restaurants) {
      if (_isInitialized && _restaurants.length == restaurants.length) {
        // Если данные не изменились, не обновляем
        return;
      }
      print('✅ УСПЕХ: Загружено ${restaurants.length} ресторанов');
      _restaurants = restaurants;
      _filteredRestaurants = restaurants;
      notifyListeners();
    }, onError: (error) {
      print('❌ ОШИБКА загрузки: $error');
    });
  }

  void filterByCuisine(String cuisine) {
    _selectedCuisine = cuisine;

    if (cuisine == 'Все') {
      _filteredRestaurants = _restaurants;
    } else {
      // ИСПРАВЛЕНИЕ: фильтруем существующие данные, а не создаем новый Stream
      _filteredRestaurants = _restaurants.where((restaurant) =>
          restaurant.cuisineType.contains(cuisine)
      ).toList();
    }
    notifyListeners();
  }

  void searchRestaurants(String query) {
    if (query.isEmpty) {
      _filteredRestaurants = _restaurants;
    } else {
      _filteredRestaurants = _restaurants
          .where(
            (restaurant) =>
                restaurant.name.toLowerCase().contains(query.toLowerCase()) ||
                restaurant.cuisineType.any(
                  (cuisine) =>
                      cuisine.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();
    }
    notifyListeners();
  }

  // ДОБАВЬТЕ ЭТОТ МЕТОД ДЛЯ ПОЛУЧЕНИЯ БЛЮД РЕСТОРАНА
  Stream<List<Dish>> getRestaurantDishes(String restaurantId) {
    return _restaurantService.getRestaurantDishes(restaurantId);
  }
}
