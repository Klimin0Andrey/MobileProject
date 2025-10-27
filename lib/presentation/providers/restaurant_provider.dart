import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/services/restaurant_service.dart';
import 'package:linux_test2/data/models/dish.dart';

class RestaurantProvider with ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  String _selectedCuisine = 'Все';

  List<Restaurant> get restaurants => _filteredRestaurants;

  List<Restaurant> get allRestaurants => _restaurants;

  String get selectedCuisine => _selectedCuisine;

  RestaurantProvider() {
    print('🔄 RestaurantProvider создан');
    _loadRestaurants();
  }

  void _loadRestaurants() {
    print('🔥 Начало загрузки ресторанов из Firestore...');

    _restaurantService.getRestaurants().listen((restaurants) {
      print('✅ УСПЕХ: Загружено ${restaurants.length} ресторанов');
      for (var restaurant in restaurants) {
        print('   - ${restaurant.name}');
      }
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
