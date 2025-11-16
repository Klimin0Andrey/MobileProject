import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/cart_item.dart';
import 'package:linux_test2/data/models/order.dart'
    as app_order; // Используем префикс, чтобы избежать конфликта имен
import 'package:linux_test2/data/models/address.dart';

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
    required DeliveryAddress deliveryAddress,
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
        deliveryAddress: deliveryAddress,
        createdAt: Timestamp.now(),
        status: app_order.OrderStatus.pending,
        phone: phone,
        paymentMethod: paymentMethod,
        comment: comment,
      );

      // Отправляем в Firestore
      await _firestore.collection('orders').add(newOrder.toMap());

      // ✅ ДОБАВЛЕНО: уведомление об успешном создании заказа
      debugPrint(
        '✅ Заказ успешно создан с адресом: ${deliveryAddress.fullAddress}',
      );
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

      _userOrders = querySnapshot.docs.map((doc) {
        return app_order.Order.fromMap(doc.data(), doc.id);
      }).toList();

      debugPrint(
        '✅ Загружено ${_userOrders.length} заказов для пользователя $userId',
      );
    } catch (e) {
      print('❌ Ошибка при загрузке заказов: $e');
      _userOrders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
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

  // ✅ ДОБАВЛЕНО: Получение заказов по статусу
  List<app_order.Order> getOrdersByStatus(app_order.OrderStatus status) {
    return _userOrders.where((order) => order.status == status).toList();
  }

  // ✅ ДОБАВЛЕНО: Обновление статуса заказа
  Future<void> updateOrderStatus(
    String orderId,
    app_order.OrderStatus newStatus,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.toString().split('.').last,
      });

      // Обновляем локальный список
      final index = _userOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        // Создаем обновленный заказ
        final updatedOrder = app_order.Order(
          id: _userOrders[index].id,
          userId: _userOrders[index].userId,
          items: _userOrders[index].items,
          totalPrice: _userOrders[index].totalPrice,
          deliveryAddress: _userOrders[index].deliveryAddress,
          createdAt: _userOrders[index].createdAt,
          status: newStatus,
          phone: _userOrders[index].phone,
          paymentMethod: _userOrders[index].paymentMethod,
          comment: _userOrders[index].comment,
          courierId: _userOrders[index].courierId,
        );

        _userOrders[index] = updatedOrder;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении статуса заказа: $e');
      rethrow;
    }
  }

  // Future<List<app_order.Order>> fetchUserOrders(String userId) async { ... }
}
