import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/providers/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final user = context.read<AppUser?>();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: пользователь не авторизован')),
      );
      return;
    }

    try {
      await orderProvider.createOrder(
        userId: user.uid,
        items: cartProvider.items,
        totalPrice: cartProvider.totalPrice,
        address: _addressController.text,
      );

      cartProvider.clearCart();

      ScaffoldMessenger.of(
        context
      ).showSnackBar(const SnackBar(content: Text('Заказ успешно оформлен!')));

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление заказа'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Список товаров
              const Text(
                'Ваш заказ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return ListTile(
                      leading: Text('${item.quantity}×'),
                      title: Text(item.dish.name),
                      trailing: Text('${item.totalPrice.toStringAsFixed(2)} ₽'),
                    );
                  },
                ),
              ),

              const Divider(),

              // Адрес доставки
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Адрес доставки',
                  hintText: 'Введите полный адрес доставки',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Введите корректный адрес (минимум 10 символов)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Итоговая сумма
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Итого:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${cartProvider.totalPrice.toStringAsFixed(2)} ₽',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Кнопка оформления
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      orderProvider.isLoading || cartProvider.items.isEmpty
                      ? null
                      : () => _placeOrder(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: orderProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Подтвердить заказ',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
