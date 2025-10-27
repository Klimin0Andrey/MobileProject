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

  void updateQuantity(String dishId, int newQuantity) {
    final existingIndex = _items.indexWhere((item) => item.dish.id == dishId);

    if (existingIndex >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void incrementQuantity(String dishId) {
    final existingIndex = _items.indexWhere((item) => item.dish.id == dishId);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String dishId) {
    final existingIndex = _items.indexWhere((item) => item.dish.id == dishId);
    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity--;
      } else {
        _items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

}