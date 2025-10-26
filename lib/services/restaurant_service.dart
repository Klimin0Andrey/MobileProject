import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/services/database.dart';
import 'package:linux_test2/data/models/dish.dart';

class RestaurantService {
  final DatabaseService _database = DatabaseService(uid: ''); // uid не нужен для ресторанов

  // Получить все рестораны
  Stream<List<Restaurant>> getRestaurants() {
    return _database.restaurants;
  }

  // Получить рестораны по кухне
  Stream<List<Restaurant>> getRestaurantsByCuisine(String cuisine) {
    return _database.getRestaurantsByCuisine(cuisine);
  }

  // Получить блюда ресторана
  Stream<List<Dish>> getRestaurantDishes(String restaurantId) {
    return _database.getDishesByRestaurant(restaurantId);
  }
}