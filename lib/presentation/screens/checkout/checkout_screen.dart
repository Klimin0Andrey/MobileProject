import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/providers/order_provider.dart';
import 'package:linux_test2/presentation/screens/checkout/order_success_screen.dart';
import 'package:linux_test2/presentation/screens/checkout/address_selection_screen.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/presentation/providers/address_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _phoneController = TextEditingController();
  final _commentsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedPaymentMethod = 'card';

  @override
  void initState() {
    super.initState();
    // Автоматически выбираем адрес по умолчанию при загрузке
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectDefaultAddress();
    });
  }

  void _selectDefaultAddress() {
    final cartProvider = context.read<CartProvider>();
    final addressProvider = context.read<AddressProvider>();

    if (cartProvider.selectedAddress == null && addressProvider.addresses.isNotEmpty) {
      final defaultAddress = addressProvider.defaultAddress;
      if (defaultAddress != null) {
        cartProvider.setDeliveryAddress(defaultAddress);
      }
    }
  }

  @override
  void dispose() {
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

    // Проверяем, что адрес выбран
    if (cartProvider.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите адрес доставки'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Подтверждение заказа',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сумма: ${cartProvider.totalPrice.toStringAsFixed(2)} ₽',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Адрес: ${cartProvider.selectedAddress!.fullAddress}', // ✅ ИСПОЛЬЗУЕМ fullAddress
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Телефон: ${_phoneController.text}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Оплата: ${_selectedPaymentMethod == 'card' ? 'Картой онлайн' : 'Наличными'}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            if (_commentsController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Комментарий: ${_commentsController.text}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Отмена',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
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
      await orderProvider.createOrder(
        userId: user.uid,
        items: cartProvider.items,
        totalPrice: cartProvider.totalPrice,
        deliveryAddress: cartProvider.selectedAddress!, // ✅ ПЕРЕДАЕМ ОБЪЕКТ АДРЕСА
        phone: _phoneController.text,
        paymentMethod: _selectedPaymentMethod,
        comment: _commentsController.text.isNotEmpty ? _commentsController.text : null,
      );

      cartProvider.clearCart();

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
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Требуется авторизация',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Для оформления заказа необходимо войти в аккаунт',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Отмена',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Войти',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Состав заказа',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...cartProvider.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
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
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${item.dish.price} ₽ × ${item.quantity}',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.totalPrice.toStringAsFixed(2)} ₽',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 12),
            Divider(color: colorScheme.onSurface.withValues(alpha: 0.3)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Итого:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
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

  Widget _buildAddressSection(CartProvider cartProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Адрес доставки',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        if (cartProvider.selectedAddress == null)
          _buildNoAddressSelected(context)
        else
          _buildSelectedAddress(context, cartProvider.selectedAddress!),
      ],
    );
  }

  Widget _buildNoAddressSelected(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Адрес не выбран',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Выберите адрес для доставки заказа',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddressSelectionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Выбрать адрес доставки'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAddress(BuildContext context, DeliveryAddress address) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  address.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'По умолчанию',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.fullAddress,
              style: const TextStyle(fontSize: 14),
            ),
            if (address.comment != null && address.comment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Комментарий: ${address.comment}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddressSelectionScreen(),
                    ),
                  );
                },
                child: const Text('Изменить адрес'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Способ оплаты',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Картой онлайн',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Безопасная оплата через Tinkoff Bank',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                value: 'card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              ),
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.money, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Наличными',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Оплата при получении заказа',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Контактные данные',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Телефон для связи',
            labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            hintText: '+7 XXX XXX XX XX',
            hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone, color: colorScheme.onSurface.withValues(alpha: 0.7)),
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
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Комментарий к заказу (необязательно)',
            labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            hintText: 'Например: домофон не работает, этаж...',
            hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.comment, color: colorScheme.onSurface.withValues(alpha: 0.7)),
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
                    _buildOrderSummary(cartProvider),
                    const SizedBox(height: 24),
                    _buildAddressSection(cartProvider),
                    const SizedBox(height: 24),
                    _buildPaymentSection(),
                    const SizedBox(height: 24),
                    _buildContactSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (orderProvider.isLoading || cartProvider.items.isEmpty || cartProvider.selectedAddress == null)
                      ? null
                      : () => _placeOrder(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (cartProvider.selectedAddress != null && !orderProvider.isLoading && cartProvider.items.isNotEmpty)
                        ? Colors.orange
                        : Colors.grey,
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
                      : Text(
                    cartProvider.selectedAddress != null
                        ? 'Подтвердить заказ'
                        : 'Выберите адрес доставки',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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