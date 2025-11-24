import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;
import 'package:linux_test2/services/notification_service.dart';

class CourierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Получить доступные заказы (готовые к доставке, статус = processing)
  Stream<List<app_order.Order>> getAvailableOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'processing')
        .orderBy('createdAt', descending: false) // Старые заказы первыми
        .snapshots()
        .map((snapshot) {
      // ✅ ИСПРАВЛЕНО: Фильтруем на клиенте заказы без курьера
      return snapshot.docs
          .where((doc) => doc.data()['courierId'] == null) // Только заказы без курьера
          .map((doc) => app_order.Order.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Получить заказы курьера (в доставке)
  Stream<List<app_order.Order>> getMyOrders(String courierId) {
    return _firestore
        .collection('orders')
        .where('courierId', isEqualTo: courierId)
        .where('status', isEqualTo: 'delivering')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => app_order.Order.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Принять заказ (назначить курьера и изменить статус на delivering)
  Future<void> acceptOrder(String orderId, String courierId) async {
    try {
      // ✅ ИСПРАВЛЕНО: Получаем заказ для получения userId
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Заказ не найден');
      }

      final orderData = orderDoc.data()!;
      final userId = orderData['userId'] as String;

      await _firestore.collection('orders').doc(orderId).update({
        'courierId': courierId,
        'status': app_order.OrderStatus.delivering.toString().split('.').last,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ ИСПРАВЛЕНО: Отправляем уведомление клиенту с userId
      await _notificationService.sendOrderStatusNotification(
        userId: userId, // ✅ ДОБАВЛЕНО
        orderId: orderId,
        title: 'Заказ в доставке',
        body: 'Курьер принял ваш заказ и везет его вам.',
      );

      print('✅ Курьер $courierId принял заказ $orderId');
    } catch (e) {
      print('❌ Ошибка при принятии заказа: $e');
      rethrow;
    }
  }

  /// Обновить позицию курьера в заказе
  Future<void> updateCourierLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'courierLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Ошибка обновления позиции курьера: $e');
      // Не пробрасываем ошибку, чтобы не прерывать обновление позиции
    }
  }

  /// Завершить заказ (статус = completed)
  Future<void> completeOrder(String orderId) async {
    try {
      // ✅ ИСПРАВЛЕНО: Получаем заказ для получения userId
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Заказ не найден');
      }

      final orderData = orderDoc.data()!;
      final userId = orderData['userId'] as String;

      await _firestore.collection('orders').doc(orderId).update({
        'status': app_order.OrderStatus.completed.toString().split('.').last,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Очищаем позицию курьера после завершения
        'courierLocation': FieldValue.delete(),
      });

      // ✅ ИСПРАВЛЕНО: Отправляем уведомление клиенту с userId
      await _notificationService.sendOrderStatusNotification(
        userId: userId, // ✅ ДОБАВЛЕНО
        orderId: orderId,
        title: 'Заказ доставлен',
        body: 'Ваш заказ успешно доставлен. Спасибо за заказ!',
      );

      print('✅ Заказ $orderId завершен');
    } catch (e) {
      print('❌ Ошибка при завершении заказа: $e');
      rethrow;
    }
  }

  /// Получить информацию о заказе (для детального просмотра)
  Future<app_order.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return app_order.Order.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Ошибка получения заказа: $e');
      return null;
    }
  }

  /// Получить поток обновлений конкретного заказа (для отслеживания)
  Stream<app_order.Order?> watchOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return app_order.Order.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }
}
