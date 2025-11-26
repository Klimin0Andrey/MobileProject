// lib/presentation/screens/checkout/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/providers/order_provider.dart';
import 'package:linux_test2/presentation/screens/checkout/order_success_screen.dart';
import 'package:linux_test2/presentation/screens/checkout/address_selection_screen.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/presentation/providers/address_provider.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';
import 'package:linux_test2/presentation/widgets/universal_image.dart';

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

  // Локальное состояние для адреса, который пользователь выбрал вручную на экране выбора.
  DeliveryAddress? _manuallySelectedAddress;

  @override
  void initState() {
    super.initState();
    // В initState теперь только заполняем телефон из профиля пользователя.
    // Управление адресом полностью перенесено в метод `build`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppUser?>();
      if (user != null && user.phone.isNotEmpty) {
        _phoneController.text = user.phone;
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  // Новый метод для навигации на экран выбора и обновления адреса.
  Future<void> _selectAddress() async {
    final selectedAddress = await Navigator.of(context).push<DeliveryAddress>(
      MaterialPageRoute(
        // AddressSelectionScreen вернет выбранный адрес
        builder: (context) => const AddressSelectionScreen(),
      ),
    );

    // Если пользователь выбрал адрес (а не просто вернулся назад),
    // обновляем наше локальное состояние, чтобы отобразить его.
    if (selectedAddress != null) {
      setState(() {
        _manuallySelectedAddress = selectedAddress;
      });
    }
  }

  Future<void> _placeOrder(
    BuildContext context,
    DeliveryAddress deliveryAddress,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final user = context.read<AppUser?>();

    if (user == null) {
      _showAuthDialog(context);
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
              'Адрес: ${deliveryAddress.fullAddress}',
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
            child: const Text(
              'Подтвердить',
              style: TextStyle(color: Colors.white),
            ),
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
        deliveryAddress: deliveryAddress,
        phone: _phoneController.text,
        paymentMethod: _selectedPaymentMethod,
        comment: _commentsController.text.isNotEmpty
            ? _commentsController.text
            : null,
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Authenticate()),
              );
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

  @override
  Widget build(BuildContext context) {
    // Используем context.watch() для подписки на изменения в провайдерах
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final addressProvider = context.watch<AddressProvider>();

    // ГЛАВНАЯ ЛОГИКА: Определяем, какой адрес показывать.
    // Эта логика будет выполняться при каждой перерисовке экрана,
    // в том числе когда AddressProvider обновится.
    DeliveryAddress? addressToShow;

    // Проверяем, существует ли еще в общем списке адрес, который пользователь выбрал вручную.
    final isManualAddressStillValid =
        _manuallySelectedAddress != null &&
        addressProvider.addresses.any(
          (a) => a.id == _manuallySelectedAddress!.id,
        );

    if (isManualAddressStillValid) {
      // Если да - используем его, это приоритет.
      addressToShow = _manuallySelectedAddress;
    } else {
      // Иначе - берем актуальный адрес по умолчанию из провайдера.
      // Если адресов нет, defaultAddress вернет null.
      addressToShow = addressProvider.defaultAddress;
    }

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
                    _buildAddressSection(addressToShow),
                    const SizedBox(height: 24),
                    _buildPaymentSection(),
                    const SizedBox(height: 24),
                    _buildContactSection(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (orderProvider.isLoading ||
                          cartProvider.items.isEmpty ||
                          addressToShow == null || addressToShow.id.isEmpty)
                      ? null
                      : () => _placeOrder(context, addressToShow!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (addressToShow != null &&
                            !orderProvider.isLoading &&
                            cartProvider.items.isNotEmpty)
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
                          addressToShow != null
                              ? 'Подтвердить заказ'
                              : 'Выберите или добавьте адрес',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Виджеты для отрисовки ---

  Widget _buildAddressSection(DeliveryAddress? address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Адрес доставки',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        // Если адрес null или у него пустой id (значит, адресов нет совсем)
        if (address == null || address.id.isEmpty)
          _buildNoAddressSelected()
        else
          _buildSelectedAddress(address),
      ],
    );
  }

  Widget _buildNoAddressSelected() {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'Адрес не выбран',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Выберите или добавьте адрес для доставки',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectAddress, // Используем наш новый метод
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Выбрать или добавить адрес'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAddress(DeliveryAddress address) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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
            Text(address.fullAddress, style: const TextStyle(fontSize: 14)),
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
                onPressed: _selectAddress,
                // ✅ ИСПРАВЛЕНО: Оранжевая кнопка
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Изменить адрес'),
              ),
            ),
          ],
        ),
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
            ...cartProvider.items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200], // Сохраняем цвет фона
                          ),
                          // Используем ClipRRect, чтобы картинка не вылезала за borderRadius
                          child: item.dish.imageUrl.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: UniversalImage(
                              imageUrl: item.dish.imageUrl,
                              fit: BoxFit.cover,
                              // Размеры берем от родителя, или можно задать явно, если нужно
                              width: 60,
                              height: 60,
                            ),
                          )
                              : null,
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
                                  color: colorScheme.onSurface.withOpacity(0.7),
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
                  ),
                )
                .toList(),
            const SizedBox(height: 12),
            Divider(color: colorScheme.onSurface.withOpacity(0.3)),
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

  Widget _buildPaymentSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Способ оплаты',
          style: TextStyle(
            fontSize: 18,
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
                    const Icon(Icons.credit_card, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Картой онлайн',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Безопасная оплата через Tinkoff Bank',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                value: 'card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) =>
                    setState(() => _selectedPaymentMethod = value!),
              ),
              RadioListTile<String>(
                title: Row(
                  children: [
                    const Icon(Icons.money, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Наличными',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Оплата при получении заказа',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                value: 'cash',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) =>
                    setState(() => _selectedPaymentMethod = value!),
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
            fontSize: 18,
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
            labelStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            hintText: '+7 XXX XXX XX XX',
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            border: const OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.phone,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
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
            labelStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            hintText: 'Например: домофон не работает, этаж...',
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            border: const OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.comment,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
