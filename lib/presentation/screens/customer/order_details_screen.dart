import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/order.dart';
import 'package:linux_test2/data/models/user.dart'; // Для проверки роли
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/screens/customer/cart_screen.dart';
import 'package:linux_test2/presentation/widgets/universal_image.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Проверяем, админ ли смотрит экран
    final user = Provider.of<AppUser?>(context);
    final isAdmin = user?.role == 'admin';

    // Цвета текста в зависимости от темы
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

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
            _buildHeaderStatus(context),
            const SizedBox(height: 24),
            _buildAddressSection(textColor, subTextColor),
            const SizedBox(height: 24),
            _buildOrderItems(textColor, subTextColor),
            const SizedBox(height: 24),
            _buildTotalSection(textColor, subTextColor),

            // Кнопка "Повторить" только для обычных пользователей
            if (!isAdmin) ...[
              const SizedBox(height: 32),
              _buildRepeatButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStatus(BuildContext context) {
    String statusText = '';
    IconData statusIcon = Icons.info;
    Color color = Colors.grey;

    switch (order.status) {
      case OrderStatus.pending:
        statusText = 'Ожидает подтверждения';
        color = Colors.grey;
        break;
      case OrderStatus.processing:
        statusText = 'Готовится';
        statusIcon = Icons.soup_kitchen;
        color = Colors.blue;
        break;
      case OrderStatus.delivering:
        statusText = 'В доставке';
        statusIcon = Icons.delivery_dining;
        color = Colors.orange;
        break;
      case OrderStatus.completed:
        statusText = 'Доставлен';
        statusIcon = Icons.check_circle;
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusText = 'Отменен';
        statusIcon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Легкий фон
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            '№ ${order.id?.substring(0, 8).toUpperCase() ?? '...'}',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(Color textColor, Color? subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Доставка', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
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
                  Text(order.deliveryAddress.title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(order.deliveryAddressString, style: TextStyle(color: textColor)),
                  if (order.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(order.phone, style: TextStyle(color: subTextColor)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItems(Color textColor, Color? subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Состав заказа', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
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
                ),
                child: item.dish.imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: UniversalImage(
                    imageUrl: item.dish.imageUrl,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  ),
                )
                    : null,
              ),
              title: Text(item.dish.name, style: TextStyle(color: textColor)),
              subtitle: Text('${item.dish.price} ₽', style: TextStyle(color: subTextColor)),
              trailing: Text('x${item.quantity}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTotalSection(Color textColor, Color? subTextColor) {
    return Column(
      children: [
        const Divider(thickness: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Итого', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            Text('${order.totalPrice.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Оплата', style: TextStyle(color: subTextColor)),
            Text(order.paymentMethod == 'card' ? 'Картой' : 'Наличными', style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
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
          final cartProvider = Provider.of<CartProvider>(context, listen: false);
          cartProvider.clearCart();
          for (var item in order.items) {
            for (int i = 0; i < item.quantity; i++) {
              cartProvider.addToCart(item.dish);
            }
          }
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartScreen()));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Товары добавлены в корзину')));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.refresh),
        label: const Text('Повторить заказ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}