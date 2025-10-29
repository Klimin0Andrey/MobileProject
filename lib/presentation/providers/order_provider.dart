import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/cart_item.dart';
import 'package:linux_test2/data/models/order.dart' as app_order; // Используем префикс, чтобы избежать конфликта имен

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> createOrder({
    required String userId,
    required List<CartItem> items,
    required double totalPrice,
    required String address,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Создаем объект заказа
      final newOrder = app_order.Order(
        userId: userId,
        items: items,
        totalPrice: totalPrice,
        address: address,
        createdAt: Timestamp.now(),
        status: app_order.OrderStatus.pending,
      );

      // Отправляем в Firestore
      await _firestore.collection('orders').add(newOrder.toMap());

    } catch (e) {
      // Здесь важна обработка ошибок
      print('Ошибка при создании заказа: $e');
      rethrow; // Пробрасываем ошибку дальше, чтобы UI мог ее показать
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// В будущем здесь будут методы для получения истории заказов
// Future<List<app_order.Order>> fetchUserOrders(String userId) async { ... }
}