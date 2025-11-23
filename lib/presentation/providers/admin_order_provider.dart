import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;
import 'package:linux_test2/services/notification_service.dart';

class AdminOrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // ✅ ИЗМЕНЕНО: Возвращаем Stream напрямую, не сохраняя в локальную переменную _allOrders.
  // Это гарантирует, что UI всегда получает свежие данные из БД.
  Stream<List<app_order.Order>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => app_order.Order.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ✅ НОВОЕ: Метод для фильтрации списка, полученного из StreamBuilder
  List<app_order.Order> filterOrdersByStatus(
      List<app_order.Order> orders, app_order.OrderStatus status) {
    return orders.where((order) => order.status == status).toList();
  }

  // Принять заказ (pending -> processing)
  Future<void> acceptOrder(String orderId) async {
    try {
      await _updateStatusAndNotify(
        orderId,
        app_order.OrderStatus.processing,
        'Заказ принят',
        'Ваш заказ принят в работу. Ресторан начал приготовление.',
      );
      debugPrint('✅ Заказ $orderId принят');
    } catch (e) {
      debugPrint('❌ Ошибка при принятии заказа: $e');
      rethrow;
    }
  }

  // Отменить заказ
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': app_order.OrderStatus.cancelled.toString().split('.').last,
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _sendNotificationIfUserExists(
          orderId,
          'Заказ отменен',
          'Причина: $reason'
      );

      debugPrint('✅ Заказ $orderId отменен');
    } catch (e) {
      debugPrint('❌ Ошибка при отмене заказа: $e');
      rethrow;
    }
  }

  // Назначить курьера вручную (опционально)
  Future<void> assignCourier(String orderId, String courierId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'courierId': courierId,
        'status': app_order.OrderStatus.delivering.toString().split('.').last,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _sendNotificationIfUserExists(
        orderId,
        'Заказ в доставке',
        'Курьер везет ваш заказ.',
      );

      debugPrint('✅ Курьер $courierId назначен на заказ $orderId');
    } catch (e) {
      debugPrint('❌ Ошибка при назначении курьера: $e');
      rethrow;
    }
  }

  // Обновить статус заказа (общий метод)
  Future<void> updateOrderStatus(String orderId, app_order.OrderStatus newStatus) async {
    try {
      await _updateStatusAndNotify(
          orderId,
          newStatus,
          'Статус заказа обновлен',
          'Новый статус: ${_getStatusText(newStatus)}'
      );
    } catch (e) {
      debugPrint('❌ Ошибка обновления статуса: $e');
      rethrow;
    }
  }

  // --- Вспомогательные методы ---

  Future<void> _updateStatusAndNotify(
      String orderId, app_order.OrderStatus status, String title, String body) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _sendNotificationIfUserExists(orderId, title, body);
  }

  Future<void> _sendNotificationIfUserExists(String orderId, String title, String body) async {
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (orderDoc.exists) {
      final userId = orderDoc.data()?['userId'] as String?;
      if (userId != null) {
        await _notificationService.sendOrderStatusNotification(
          userId: userId,
          title: title,
          body: body,
          orderId: orderId,
        );
      }
    }
  }

  String _getStatusText(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending: return 'Ожидает';
      case app_order.OrderStatus.processing: return 'Готовится';
      case app_order.OrderStatus.delivering: return 'В пути';
      case app_order.OrderStatus.completed: return 'Доставлен';
      case app_order.OrderStatus.cancelled: return 'Отменен';
    }
  }
}