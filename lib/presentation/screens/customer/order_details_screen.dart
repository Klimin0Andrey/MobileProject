import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/order.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/screens/customer/cart_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали заказа'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderStatus(),
            const SizedBox(height: 24),
            _buildAddressSection(),
            const SizedBox(height: 24),
            _buildOrderItems(),
            const SizedBox(height: 24),
            _buildTotalSection(),
            const SizedBox(height: 32),
            _buildRepeatButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStatus() {
    String statusText = '';
    IconData statusIcon = Icons.info;
    Color color = Colors.grey;

    switch (order.status) {
      case OrderStatus.pending:
        statusText = 'Заказ ожидает подтверждения';
        color = Colors.grey;
        break;
      case OrderStatus.processing:
        statusText = 'Ресторан готовит ваш заказ';
        statusIcon = Icons.soup_kitchen;
        color = Colors.blue;
        break;
      case OrderStatus.delivering:
        statusText = 'Курьер везет ваш заказ';
        statusIcon = Icons.delivery_dining;
        color = Colors.orange;
        break;
      case OrderStatus.completed:
        statusText = 'Заказ доставлен. Приятного аппетита!';
        statusIcon = Icons.check_circle;
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusText = 'Заказ отменен';
        statusIcon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            '№ заказа: ${order.id?.substring(0, 8) ?? '...'}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Доставка', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.deliveryAddress.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(order.deliveryAddressString),
                  if (order.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(order.phone, style: const TextStyle(color: Colors.grey)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Состав заказа', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: order.items.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final item = order.items[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  image: item.dish.imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(item.dish.imageUrl), fit: BoxFit.cover)
                      : null,
                ),
              ),
              title: Text(item.dish.name),
              subtitle: Text('${item.dish.price} ₽'),
              trailing: Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Column(
      children: [
        const Divider(thickness: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Итого', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${order.totalPrice.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Оплата', style: TextStyle(color: Colors.grey)),
            Text(order.paymentMethod == 'card' ? 'Картой' : 'Наличными', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeatButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Логика повтора заказа
          final cartProvider = Provider.of<CartProvider>(context, listen: false);

          // 1. Очищаем текущую корзину
          cartProvider.clearCart();

          // 2. Добавляем товары из истории
          for (var item in order.items) {
            // ИСПРАВЛЕНИЕ: Так как addToCart принимает только блюдо и добавляет +1,
            // вызываем его в цикле нужное количество раз.
            for (int i = 0; i < item.quantity; i++) {
              cartProvider.addToCart(item.dish);
            }
          }

          // 3. Переходим в корзину
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CartScreen()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Товары добавлены в корзину')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.refresh),
        label: const Text('Повторить заказ'),
      ),
    );
  }
}