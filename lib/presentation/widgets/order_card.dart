import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linux_test2/data/models/order.dart';
import 'package:linux_test2/presentation/screens/customer/order_details_screen.dart'; // Создадим ниже

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Переход к деталям заказа
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Верхняя часть: Дата и Статус ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Заказ от ${DateFormat('dd.MM, HH:mm', 'ru').format(order.createdAt.toDate())}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.totalPrice.toStringAsFixed(0)} ₽ • ${order.items.length} поз.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  _buildStatusChip(order.status),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // --- Адрес и Иконка ---
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddressString,
                      // Используем строку адреса из модели
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // --- Превью товаров (первые 2-3 шт) ---
              Text(
                order.items.map((item) => item.dish.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.grey;
        text = 'Создан';
        icon = Icons.access_time;
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        text = 'Готовится';
        icon = Icons.soup_kitchen;
        break;
      case OrderStatus.delivering:
        color = Colors.orange;
        text = 'В пути';
        icon = Icons.delivery_dining;
        break;
      case OrderStatus.completed:
        color = Colors.green;
        text = 'Доставлен';
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Отменён';
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
