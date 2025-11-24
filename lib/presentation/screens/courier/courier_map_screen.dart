import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;
import 'package:linux_test2/presentation/providers/courier_provider.dart';
import 'package:linux_test2/services/location_service.dart';
import 'package:linux_test2/presentation/screens/order_chat_screen.dart';

class CourierMapScreen extends StatefulWidget {
  final app_order.Order order;

  const CourierMapScreen({
    super.key,
    required this.order,
  });

  @override
  State<CourierMapScreen> createState() => _CourierMapScreenState();
}

class _CourierMapScreenState extends State<CourierMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  Timer? _locationUpdateTimer;
  LatLng? _courierPosition;
  List<LatLng>? _route;
  bool _isLoadingRoute = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    // Получаем текущую позицию курьера
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _courierPosition = LatLng(position.latitude, position.longitude);
      });

      // Центрируем карту на позиции курьера
      _mapController.move(_courierPosition!, 15);

      // Рассчитываем маршрут
      await _calculateRoute();

      // Начинаем периодическое обновление позиции
      _startLocationTracking();
    } else {
      // Если не удалось получить позицию, центрируем на адресе доставки
      final deliveryLat = widget.order.deliveryAddress.lat;
      final deliveryLng = widget.order.deliveryAddress.lng;
      if (deliveryLat != null && deliveryLng != null) {
        final deliveryPoint = LatLng(deliveryLat, deliveryLng);
        _mapController.move(deliveryPoint, 15);
      }
    }
  }

  Future<void> _calculateRoute() async {
    if (_courierPosition == null) return;

    final deliveryLat = widget.order.deliveryAddress.lat;
    final deliveryLng = widget.order.deliveryAddress.lng;

    if (deliveryLat == null || deliveryLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Адрес доставки не содержит координат')),
      );
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      final courierProvider = Provider.of<CourierProvider>(context, listen: false);
      final calculatedRoute = await courierProvider.calculateRouteForOrder(
        start: _courierPosition!,
        end: LatLng(deliveryLat, deliveryLng),
      );

      if (mounted) {
        setState(() {
          _route = calculatedRoute;
          _isLoadingRoute = false;
        });

        // Центрируем карту так, чтобы был виден весь маршрут
        if (_route != null && _route!.isNotEmpty) {
          _fitBounds();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка расчета маршрута: $e')),
        );
      }
    }
  }

  void _fitBounds() {
    if (_courierPosition == null || _route == null || _route!.isEmpty) return;

    final deliveryLat = widget.order.deliveryAddress.lat;
    final deliveryLng = widget.order.deliveryAddress.lng;
    if (deliveryLat == null || deliveryLng == null) return;

    final deliveryPoint = LatLng(deliveryLat, deliveryLng);

    // Создаем границы, включающие позицию курьера и адрес доставки
    final bounds = LatLngBounds.fromPoints([
      _courierPosition!,
      deliveryPoint,
    ]);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _startLocationTracking() {
    // Обновляем позицию каждые 5 секунд
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _courierPosition = LatLng(position.latitude, position.longitude);
        });

        // Обновляем позицию в Firestore
        final courierProvider = Provider.of<CourierProvider>(context, listen: false);
        await courierProvider.updateLocation(widget.order.id!);

        // Пересчитываем маршрут, если позиция изменилась значительно
        if (_route != null) {
          await _calculateRoute();
        }
      }
    });
  }

  Future<void> _completeOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить заказ?'),
        content: const Text('Вы уверены, что доставили заказ клиенту?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isCompleting = true);

      try {
        final courierProvider = Provider.of<CourierProvider>(context, listen: false);
        await courierProvider.completeOrder(widget.order.id!);

        if (mounted) {
          Navigator.pop(context, true); // Возвращаемся с флагом успеха
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заказ успешно завершен!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isCompleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
        title: Text('Заказ #${widget.order.id?.substring(0, 8) ?? 'N/A'}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
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

              // МАРШРУТ (линия)
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
                  // Позиция курьера
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

          // ИНДИКАТОР ЗАГРУЗКИ МАРШРУТА
          if (_isLoadingRoute)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Расчет маршрута...'),
                    ],
                  ),
                ),
              ),
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
                  // Адрес доставки
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.order.deliveryAddressString,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Телефон клиента
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        widget.order.phone,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ ДОБАВЛЕНО: Кнопка "Чат с клиентом"
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OrderChatScreen(order: widget.order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Чат с клиентом'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Кнопка "Завершить заказ"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCompleting ? null : _completeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCompleting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle),
                          SizedBox(width: 8),
                          Text(
                            'Завершить заказ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}