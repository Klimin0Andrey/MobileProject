import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linux_test2/data/models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.completed:
        color = Colors.green;
        text = 'Завершён';
        break;
      case OrderStatus.delivering:
        color = Colors.orange;
        text = 'Доставляется';
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        text = 'Готовится';
        break;
      case OrderStatus.pending:
        color = Colors.grey;
        text = 'В обработке';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Отменён';
        break;
      default:
        color = Colors.grey;
        text = 'Неизвестно';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Заголовок с датой и статусом ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // УЛУЧШЕНИЕ: Используем пакет intl для более надежного и локализуемого форматирования
                Text(
                  'Заказ от ${DateFormat('dd.MM.yyyy, HH:mm', 'ru').format(order.createdAt.toDate())}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // --- Состав заказа ---
            const Text(
              'Состав заказа:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        // ИСПРАВЛЕНИЕ: Используем правильное обращение к имени блюда через item.dish.name
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(
                              context,
                            ).style.copyWith(fontSize: 14),
                            children: [
                              const TextSpan(text: '• '),
                              TextSpan(text: item.dish.name),
                              // ПРАВИЛЬНЫЙ ПУТЬ К ИМЕНИ
                              TextSpan(
                                text: ' × ${item.quantity}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(), // ДОБАВЛЯЕМ .toList() для spread оператора

                if (order.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '... и ещё ${order.items.length - 3} позиций',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),

            // --- Итоговая сумма ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Итого:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${order.totalPrice.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
