// presentation/providers/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/cart_item.dart';
import 'package:linux_test2/data/models/dish.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(Dish dish) {
    final existingIndex = _items.indexWhere((item) => item.dish.id == dish.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(dish: dish));
    }
    notifyListeners();
  }

  void removeFromCart(String dishId) {
    _items.removeWhere((item) => item.dish.id == dishId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}