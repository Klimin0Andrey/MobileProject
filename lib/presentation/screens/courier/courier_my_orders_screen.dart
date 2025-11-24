import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/courier_provider.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;
import 'package:linux_test2/presentation/screens/courier/courier_map_screen.dart';

class CourierMyOrdersScreen extends StatelessWidget {
  const CourierMyOrdersScreen({super.key});

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
        title: const Text('Мои заказы'),
      ),
      body: StreamBuilder<List<app_order.Order>>(
        stream: courierProvider.getMyOrders(user.uid),
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
                  Icon(Icons.delivery_dining, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Нет активных заказов',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Примите заказ из раздела "Доступные"',
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
              return _buildOrderCard(context, orders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, app_order.Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.delivery_dining, color: Colors.orange),
        title: Text('Заказ #${order.id?.substring(0, 8) ?? 'N/A'}'),
        subtitle: Text(
          order.deliveryAddressString,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${order.totalPrice.toStringAsFixed(2)} ₽',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        onTap: () {
          // ✅ ИЗМЕНЕНО: Открываем экран карты
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourierMapScreen(order: order),
            ),
          ).then((completed) {
            // Если заказ завершен, обновляем список
            if (completed == true) {
              // StreamBuilder автоматически обновит список
            }
          });
        },
      ),
    );
  }
}
