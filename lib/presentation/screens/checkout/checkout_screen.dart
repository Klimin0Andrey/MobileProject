import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/providers/order_provider.dart';
import 'package:linux_test2/presentation/screens/checkout/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commentsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedPaymentMethod = 'card';
  List<String> _savedAddresses = []; // Пока пустой, потом из профиля

  @override
  void initState() {
    super.initState();
    // Здесь потом будет загрузка сохраненных адресов из профиля
    _savedAddresses = [
      'ул. Ленина, д. 10, кв. 25',
      'пр. Мира, д. 45, кв. 12',
    ];
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final user = context.read<AppUser?>();

    if (user == null) {
      _showAuthDialog(context);
      return;
    }

    // Подтверждение заказа
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение заказа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сумма: ${cartProvider.totalPrice.toStringAsFixed(2)} ₽'),
            const SizedBox(height: 8),
            Text('Адрес: ${_addressController.text}'),
            const SizedBox(height: 8),
            Text('Телефон: ${_phoneController.text}'),
            const SizedBox(height: 8),
            Text('Оплата: ${_selectedPaymentMethod == 'card' ? 'Картой онлайн' : 'Наличными'}'),
            if (_commentsController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Комментарий: ${_commentsController.text}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Подтвердить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // ИСПРАВЛЯЕМ ВЫЗОВ CREATEORDER - ПЕРЕДАЕМ ВСЕ ДАННЫЕ
      await orderProvider.createOrder(
        userId: user.uid,
        items: cartProvider.items,
        totalPrice: cartProvider.totalPrice,
        address: _addressController.text,
        // ПЕРЕДАЕМ НОВЫЕ ДАННЫЕ ИЗ ФОРМЫ
        phone: _phoneController.text,
        paymentMethod: _selectedPaymentMethod,
        comment: _commentsController.text.isNotEmpty ? _commentsController.text : null,
      );

      cartProvider.clearCart();

      // Переходим на экран успеха
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при создании заказа: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется авторизация'),
        content: const Text('Для оформления заказа необходимо войти в аккаунт'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Здесь навигация на экран авторизации
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Состав заказа',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...cartProvider.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // Изображение блюда
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: item.dish.imageUrl.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(item.dish.imageUrl),
                        fit: BoxFit.cover,
                      )
                          : null,
                      color: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.dish.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${item.dish.price} ₽ × ${item.quantity}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.totalPrice.toStringAsFixed(2)} ₽',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Итого:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Адрес доставки',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Адрес доставки',
            hintText: 'Улица, дом, квартира, этаж, домофон',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите адрес доставки';
            }
            if (value.trim().length < 10) {
              return 'Адрес должен содержать минимум 10 символов';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Способ оплаты',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Картой онлайн'),
                  ],
                ),
                subtitle: const Text('Безопасная оплата через Tinkoff Bank'),
                value: 'card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              ),
              RadioListTile<String>(
                title: const Row(
                  children: [
                    Icon(Icons.money, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Наличными'),
                  ],
                ),
                subtitle: const Text('Оплата при получении заказа'),
                value: 'cash',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Контактные данные',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Телефон для связи',
            hintText: '+7 XXX XXX XX XX',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Введите номер телефона';
            }
            if (value.length < 5) {
              return 'Введите корректный номер телефона';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _commentsController,
          decoration: const InputDecoration(
            labelText: 'Комментарий к заказу (необязательно)',
            hintText: 'Например: домофон не работает, этаж...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.comment),
          ),
          maxLines: 3,
        ),
      ],
    );
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
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Состав заказа
                    _buildOrderSummary(cartProvider),

                    const SizedBox(height: 24),

                    // 2. Адрес доставки
                    _buildAddressSection(),

                    const SizedBox(height: 24),

                    // 3. Способ оплаты
                    _buildPaymentSection(),

                    const SizedBox(height: 24),

                    // 4. Контактные данные и комментарий
                    _buildContactSection(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Кнопка оформления (фиксированная внизу)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: orderProvider.isLoading || cartProvider.items.isEmpty
                      ? null
                      : () => _placeOrder(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: orderProvider.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Подтвердить заказ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}