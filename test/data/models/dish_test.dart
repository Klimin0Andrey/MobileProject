import 'package:flutter_test/flutter_test.dart';
import 'package:linux_test2/data/models/dish.dart';

void main() {
  test('Dish.fromMap correctly parses data', () {
    // Имитация данных из Firebase
    final Map<String, dynamic> data = {
      'name': 'Sushi',
      'price': 500.0,
      'description': 'Yummy',
      'imageUrl': 'http://img.com',
      'category': 'Japanese',
      'restaurantId': '123',
      'isAvailable': true,
    };

    final dish = Dish.fromMap(data, 'docId_1');

    expect(dish.id, 'docId_1');
    expect(dish.name, 'Sushi');
    expect(dish.price, 500.0);
  });
}