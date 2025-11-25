import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/services/restaurant_service.dart';
import 'package:linux_test2/data/models/dish.dart';

// ✅ ДОБАВЛЕНО: Enum для типов сортировки
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
  
  // ✅ ДОБАВЛЕНО: Переменные для сортировки и фильтрации
  SortType _sortType = SortType.none;
  double _minRating = 0.0;  // Минимальный рейтинг для фильтрации
  String _searchQuery = '';  // Сохраняем поисковый запрос

  List<Restaurant> get restaurants => _filteredRestaurants;
  List<Restaurant> get allRestaurants => _restaurants;
  String get selectedCuisine => _selectedCuisine;
  SortType get sortType => _sortType;
  double get minRating => _minRating;

  RestaurantProvider() {
    print('🔄 RestaurantProvider создан');
    _loadRestaurants();
  }

  void _loadRestaurants() {
    print('🔥 Начало загрузки ресторанов из Firestore...');

    if (!_isInitialized) {
      _restaurantService.getRestaurants().first.then((restaurants) {
        _restaurants = restaurants;
        _applyFiltersAndSort();
        _isInitialized = true;
        notifyListeners();
        print('✅ Загружено из кэша: ${restaurants.length} ресторанов');
      }).catchError((error) {
        print('❌ Ошибка загрузки из кэша: $error');
      });
    }

    _restaurantService.getRestaurants().listen((restaurants) {
      if (_isInitialized && _restaurants.length == restaurants.length) {
        return;
      }
      print('✅ УСПЕХ: Загружено ${restaurants.length} ресторанов');
      _restaurants = restaurants;
      _applyFiltersAndSort();
      notifyListeners();
    }, onError: (error) {
      print('❌ ОШИБКА загрузки: $error');
    });
  }

  // ✅ ДОБАВЛЕНО: Применение всех фильтров и сортировки
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
        // Парсим время доставки (например, "30-40 мин" -> берем первое число)
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
        // Без сортировки
        break;
    }

    _filteredRestaurants = result;
  }

  // ✅ ДОБАВЛЕНО: Парсинг времени доставки
  int _parseDeliveryTime(String deliveryTime) {
    // Примеры: "30-40 мин", "45 мин", "20-30 минут"
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(deliveryTime);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 999;
    }
    return 999; // Если не удалось распарсить, ставим в конец
  }

  void filterByCuisine(String cuisine) {
    _selectedCuisine = cuisine;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void searchRestaurants(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // ✅ ДОБАВЛЕНО: Сортировка ресторанов
  void sortRestaurants(SortType sortType) {
    _sortType = sortType;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // ✅ ДОБАВЛЕНО: Фильтрация по рейтингу
  void filterByRating(double minRating) {
    _minRating = minRating;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // ✅ ДОБАВЛЕНО: Сброс всех фильтров
  void resetFilters() {
    _selectedCuisine = 'Все';
    _minRating = 0.0;
    _searchQuery = '';
    _sortType = SortType.none;
    _applyFiltersAndSort();
    notifyListeners();
  }

  Stream<List<Dish>> getRestaurantDishes(String restaurantId) {
    return _restaurantService.getRestaurantDishes(restaurantId);
  }
}
