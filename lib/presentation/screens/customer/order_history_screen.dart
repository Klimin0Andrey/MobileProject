import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/order_provider.dart';
import 'package:linux_test2/presentation/widgets/order_card.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:linux_test2/presentation/screens/home_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  Future<void>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = initializeDateFormatting('ru', null).then((_) {
      final user = Provider.of<AppUser?>(context, listen: false);
      if (user != null) {
        return Provider.of<OrderProvider>(context, listen: false)
            .fetchUserOrders(user.uid);
      }
    });
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _loadOrders();
    });
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('История заказов'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: user == null ? _buildGuestView() : _buildOrderHistory(),
    );
  }

  Widget _buildGuestView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Войдите, чтобы увидеть историю заказов',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistory() {
    return FutureBuilder<void>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        return Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            // Состояние загрузки (показываем только в самом начале)
            if (orderProvider.isLoading && orderProvider.userOrders.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'Загружаем историю заказов...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Ошибка загрузки
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Не удалось загрузить заказы',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ошибка: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refreshOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Повторить попытку'),
                    ),
                  ],
                ),
              );
            }

            // Данные заказов
            final orders = orderProvider.userOrders;

            // Нет заказов
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                    const SizedBox(height: 24),
                    const Text(
                      'У вас ещё нет заказов',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Сделайте свой первый заказ!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('К ресторанам'),
                    ),
                  ],
                ),
              );
            }

            // Список заказов с возможностью обновления
            return RefreshIndicator(
              onRefresh: _refreshOrders,
              color: Colors.orange,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return OrderCard(order: orders[index]);
                },
              ),
            );
          },
        );
      },
    );
  }
}