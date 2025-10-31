import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/cart_item.dart';
import 'package:linux_test2/data/models/order.dart' as app_order; // Используем префикс, чтобы избежать конфликта имен

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<app_order.Order> _userOrders = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<app_order.Order> get userOrders => _userOrders;

  Future<void> createOrder({
    required String userId,
    required List<CartItem> items,
    required double totalPrice,
    required String address,
    required String phone,
    required String paymentMethod,
    String? comment,
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
        phone: phone,
        paymentMethod: paymentMethod,
        comment: comment,
      );

      // Отправляем в Firestore
      await _firestore.collection('orders').add(newOrder.toMap());
    } catch (e) {
      print('Ошибка при создании заказа: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserOrders(String userId) async {
    if (userId.isEmpty) {
      _userOrders = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where(
            'userId',
            isEqualTo: userId,
          ) // Фильтруем заказы по ID пользователя
          .orderBy(
            'createdAt',
            descending: true,
          ) // Сортируем, чтобы новые были сверху
          .get();

      // Преобразуем документы из Firestore в список объектов Order
      _userOrders = querySnapshot.docs.map((doc) {
        return app_order.Order.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('❌ Ошибка при загрузке заказов: $e');
      _userOrders = []; // В случае ошибки возвращаем пустой список
    } finally {
      _isLoading = false;
      notifyListeners(); // Уведомляем UI, что загрузка завершена (успешно или нет)
    }
  }

  // ДОПОЛНИТЕЛЬНО: Метод для очистки истории заказов
  void clearOrders() {
    _userOrders = [];
    notifyListeners();
  }

  // ДОПОЛНИТЕЛЬНО: Поиск заказа по ID
  app_order.Order? getOrderById(String orderId) {
    try {
      return _userOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Future<List<app_order.Order>> fetchUserOrders(String userId) async { ... }
}
