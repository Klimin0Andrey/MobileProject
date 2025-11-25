import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/courier_provider.dart';
import 'package:linux_test2/services/route_service.dart';
import 'package:linux_test2/services/location_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class CourierOrdersScreen extends StatelessWidget {
  const CourierOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courierProvider = Provider.of<CourierProvider>(context, listen: false);
    final user = Provider.of<AppUser?>(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Ошибка: пользователь не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные заказы'),
        actions: [
          // ✅ ДОБАВЛЕНО: Переключатель онлайн/офлайн
          Consumer<CourierProvider>(
            builder: (context, provider, _) {
              return Switch(
                value: provider.isOnline,
                onChanged: (value) {
                  provider.toggleOnlineStatus();
                },
                activeColor: Colors.green,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<app_order.Order>>(
        stream: courierProvider.getAvailableOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Нет доступных заказов',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Заказы появятся здесь, когда ресторан\nначнет их готовить',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orders[index], user.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, app_order.Order order, String courierId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () => _showOrderDetails(context, order, courierId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Заказ #${order.id?.substring(0, 8) ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${order.totalPrice.toStringAsFixed(2)} ₽',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddressString,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.restaurant_menu, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} ${_getItemsText(order.items.length)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(order.createdAt.toDate()),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (order.comment != null && order.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.comment!,
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _acceptOrder(context, order, courierId),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Принять заказ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getItemsText(int count) {
    if (count == 1) return 'блюдо';
    if (count >= 2 && count <= 4) return 'блюда';
    return 'блюд';
  }

  Future<void> _acceptOrder(BuildContext context, app_order.Order order, String courierId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Принять заказ?'),
        content: Text('Вы уверены, что хотите принять заказ на сумму ${order.totalPrice.toStringAsFixed(2)} ₽?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Принять'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final courierProvider = Provider.of<CourierProvider>(context, listen: false);
        await courierProvider.acceptOrder(order.id!, courierId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заказ принят! Перейдите в "Мои заказы"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  Future<void> _showOrderDetails(BuildContext context, app_order.Order order, String courierId) async {
    // Показываем детали заказа в диалоге
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Заказ #${order.id?.substring(0, 8) ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Адрес: ${order.deliveryAddressString}'),
              const SizedBox(height: 8),
              Text('Телефон: ${order.phone}'),
              const SizedBox(height: 8),
              Text('Сумма: ${order.totalPrice.toStringAsFixed(2)} ₽'),
              const SizedBox(height: 8),
              const Text('Состав:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('• ${item.dish.name} x${item.quantity}'),
              )),
              if (order.comment != null && order.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Комментарий: ${order.comment}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptOrder(context, order, courierId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Принять'),
          ),
        ],
      ),
    );
  }
}


