import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/services/restaurant_service.dart';
import 'package:linux_test2/data/models/dish.dart';
import 'dart:async';

// ✅ ДОБАВИТЬ: Enum для типов сортировки
enum SortType {
  none,           // Без сортировки
  ratingDesc,     // По рейтингу (высокий → низкий)
  ratingAsc,      // По рейтингу (низкий → высокий)
  deliveryTime,   // По времени доставки
  nameAsc,        // По названию (А → Я)
  nameDesc,       // По названию (Я → А)
}

class RestaurantProvider with ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  String _selectedCuisine = 'Все';
  bool _isInitialized = false;

  // ✅ ДОБАВИТЬ: Переменные для фильтров и сортировки
  double _minRating = 0.0;
  String _searchQuery = '';
  SortType _sortType = SortType.none;

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

  // ✅ ДОБАВИТЬ: Применение всех фильтров и сортировки
  void _applyFiltersAndSort() {
    List<Restaurant> result = List.from(_restaurants);

    // 1. Фильтр по кухне
    if (_selectedCuisine != 'Все') {
      result = result.where((restaurant) =>
          restaurant.cuisineType.contains(_selectedCuisine)
      ).toList();
    }

    // 2. Фильтр по рейтингу
    if (_minRating > 0.0) {
      result = result.where((restaurant) =>
          restaurant.rating >= _minRating
      ).toList();
    }

    // 3. Поиск
    if (_searchQuery.isNotEmpty) {
      result = result.where(
        (restaurant) =>
            restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            restaurant.cuisineType.any(
              (cuisine) =>
                  cuisine.toLowerCase().contains(_searchQuery.toLowerCase()),
            ),
      ).toList();
    }

    // 4. Сортировка
    switch (_sortType) {
      case SortType.ratingDesc:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortType.ratingAsc:
        result.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case SortType.deliveryTime:
        result.sort((a, b) {
          final aTime = _parseDeliveryTime(a.deliveryTime);
          final bTime = _parseDeliveryTime(b.deliveryTime);
          return aTime.compareTo(bTime);
        });
        break;
      case SortType.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.nameDesc:
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortType.none:
        break;
    }

    _filteredRestaurants = result;
  }

  // ✅ ДОБАВИТЬ: Парсинг времени доставки
  int _parseDeliveryTime(String deliveryTime) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(deliveryTime);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 999;
    }
    return 999;
  }

  // ✅ ДОБАВИТЬ: Обновить filterByCuisine для использования _applyFiltersAndSort
  void filterByCuisine(String cuisine) {
    _selectedCuisine = cuisine;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // ✅ ДОБАВИТЬ: Обновить searchRestaurants для использования _applyFiltersAndSort
  void searchRestaurants(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // ✅ ДОБАВИТЬ: Сортировка ресторанов
  void sortRestaurants(SortType sortType) {
    _sortType = sortType;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // ✅ ДОБАВИТЬ: Фильтрация по рейтингу
  void filterByRating(double minRating) {
    _minRating = minRating;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // ✅ ДОБАВИТЬ: Сброс всех фильтров
  void resetFilters() {
    _selectedCuisine = 'Все';
    _minRating = 0.0;
    _searchQuery = '';
    _sortType = SortType.none;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // ✅ ДОБАВИТЬ: Геттеры
  SortType get sortType => _sortType;
  double get minRating => _minRating;

  // ДОБАВЬТЕ ЭТОТ МЕТОД ДЛЯ ПОЛУЧЕНИЯ БЛЮД РЕСТОРАНА
  Stream<List<Dish>> getRestaurantDishes(String restaurantId) {
    return _restaurantService.getRestaurantDishes(restaurantId);
  }
}
