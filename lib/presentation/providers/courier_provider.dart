import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;
import 'package:linux_test2/services/courier_service.dart';
import 'package:linux_test2/services/route_service.dart';
import 'package:linux_test2/services/location_service.dart';
import 'package:latlong2/latlong.dart';

class CourierProvider with ChangeNotifier {
  final CourierService _courierService = CourierService();
  final RouteService _routeService = RouteService();
  final LocationService _locationService = LocationService();

  bool _isOnline = false;
  String? _currentOrderId;
  LatLng? _currentLocation;
  List<LatLng>? _currentRoute;

  bool get isOnline => _isOnline;
  String? get currentOrderId => _currentOrderId;
  LatLng? get currentLocation => _currentLocation;
  List<LatLng>? get currentRoute => _currentRoute;

  /// Получить доступные заказы
  Stream<List<app_order.Order>> getAvailableOrders() {
    return _courierService.getAvailableOrders();
  }

  /// Получить заказы курьера
  Stream<List<app_order.Order>> getMyOrders(String courierId) {
    return _courierService.getMyOrders(courierId);
  }

  /// Принять заказ
  Future<void> acceptOrder(String orderId, String courierId) async {
    try {
      await _courierService.acceptOrder(orderId, courierId);
      _currentOrderId = orderId;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Ошибка принятия заказа: $e');
      rethrow;
    }
  }

  /// Завершить заказ
  Future<void> completeOrder(String orderId) async {
    try {
      await _courierService.completeOrder(orderId);
      if (_currentOrderId == orderId) {
        _currentOrderId = null;
        _currentRoute = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Ошибка завершения заказа: $e');
      rethrow;
    }
  }

  /// Рассчитать маршрут для заказа
  Future<List<LatLng>> calculateRouteForOrder({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final route = await _routeService.calculateRoute(start: start, end: end);
      _currentRoute = route;
      notifyListeners();
      return route;
    } catch (e) {
      debugPrint('❌ Ошибка расчета маршрута: $e');
      rethrow;
    }
  }

  /// Начать отслеживание позиции курьера
  Future<void> startLocationTracking(String orderId) async {
    try {
      // Получаем текущую позицию
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        
        // Обновляем позицию в заказе
        await _courierService.updateCourierLocation(
          orderId: orderId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения позиции: $e');
    }
  }

  /// Обновить позицию курьера (вызывается периодически)
  Future<void> updateLocation(String orderId) async {
    if (_currentOrderId != orderId) return;
    
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        
        await _courierService.updateCourierLocation(
          orderId: orderId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Ошибка обновления позиции: $e');
    }
  }

  /// Получить поток обновлений заказа (для отслеживания)
  Stream<app_order.Order?> watchOrder(String orderId) {
    return _courierService.watchOrder(orderId);
  }

  /// Переключить статус онлайн/офлайн
  void toggleOnlineStatus() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  /// Очистить текущий маршрут
  void clearRoute() {
    _currentRoute = null;
    notifyListeners();
  }
}
