import 'package:linux_test2/data/models/dish.dart';

class CartItem {
  final Dish dish;
  int quantity;

  CartItem({
    required this.dish,
    this.quantity = 1,
  });

  double get totalPrice => dish.price * quantity;
}