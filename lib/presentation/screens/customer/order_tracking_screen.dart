import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;
import 'package:linux_test2/services/courier_service.dart';
import 'package:linux_test2/presentation/screens/order_chat_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final app_order.Order order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  final CourierService _courierService = CourierService();

  StreamSubscription<app_order.Order?>? _orderSubscription;
  LatLng? _courierPosition;
  List<LatLng>? _route;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _startTracking() {
    if (widget.order.id == null) return;

    // Слушаем обновления заказа в реальном времени
    _orderSubscription = _courierService.watchOrder(widget.order.id!).listen(
          (order) {
        if (order != null && mounted) {
          setState(() {
            // ✅ ИСПРАВЛЕНО:
            // В OrderModel поле courierPosition уже имеет тип LatLng.
            // Мы просто присваиваем его переменной состояния.
            if (order.courierPosition != null) {
              _courierPosition = order.courierPosition;

              // Центрируем карту на позиции курьера
              // Используем текущий zoom (или фиксированный 15.0)
              _mapController.move(_courierPosition!, 15.0);
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка отслеживания: $error')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryLat = widget.order.deliveryAddress.lat;
    final deliveryLng = widget.order.deliveryAddress.lng;
    final deliveryPoint = deliveryLat != null && deliveryLng != null
        ? LatLng(deliveryLat, deliveryLng)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Отслеживание заказа #${widget.order.id?.substring(0, 8) ?? 'N/A'}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        // ✅ Кнопка "Назад" уже есть по умолчанию в AppBar
      ),
      body: Stack(
        children: [
          // КАРТА
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _courierPosition ?? deliveryPoint ?? const LatLng(55.751244, 37.618423),
              initialZoom: 15,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.linux_test2',
              ),

              // МАРШРУТ (если есть позиция курьера)
              if (_route != null && _route!.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!,
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),

              // МАРКЕРЫ
              MarkerLayer(
                markers: [
                  // Позиция курьера (если известна)
                  if (_courierPosition != null)
                    Marker(
                      point: _courierPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.delivery_dining,
                        color: Colors.orange,
                        size: 40,
                      ),
                    ),

                  // Адрес доставки
                  if (deliveryPoint != null)
                    Marker(
                      point: deliveryPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // НИЖНЯЯ ПАНЕЛЬ С ИНФОРМАЦИЕЙ
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Статус заказа
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(widget.order.status),
                        color: _getStatusColor(widget.order.status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(widget.order.status),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(widget.order.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Адрес доставки
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.order.deliveryAddressString,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Информация о курьере (если назначен)
                  if (widget.order.courierId != null)
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Курьер в пути',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // ✅ ДОБАВЛЕНО: Кнопка "Чат с курьером" (если курьер назначен)
                  if (widget.order.courierId != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OrderChatScreen(order: widget.order),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Чат с курьером'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return Icons.access_time;
      case app_order.OrderStatus.processing:
        return Icons.restaurant;
      case app_order.OrderStatus.delivering:
        return Icons.delivery_dining;
      case app_order.OrderStatus.completed:
        return Icons.check_circle;
      case app_order.OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return Colors.orange;
      case app_order.OrderStatus.processing:
        return Colors.blue;
      case app_order.OrderStatus.delivering:
        return Colors.green;
      case app_order.OrderStatus.completed:
        return Colors.green;
      case app_order.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return 'Ожидает подтверждения';
      case app_order.OrderStatus.processing:
        return 'Готовится';
      case app_order.OrderStatus.delivering:
        return 'В доставке';
      case app_order.OrderStatus.completed:
        return 'Доставлен';
      case app_order.OrderStatus.cancelled:
        return 'Отменен';
    }
  }
}