import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/data/models/order.dart'; // Импорт модели OrderStatus
import 'package:linux_test2/presentation/providers/order_provider.dart';
import 'package:linux_test2/presentation/widgets/order_card.dart';
import 'package:intl/date_symbol_data_local.dart';


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

    if (user == null) return _buildGuestView();

    return DefaultTabController(
      length: 2, // Две вкладки: Активные и История
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои заказы'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Активные'),
              Tab(text: 'История'),
            ],
          ),
        ),
        body: FutureBuilder<void>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            return Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading && orderProvider.userOrders.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }

                if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
                  return _buildErrorView(snapshot.error.toString());
                }

                // Разделяем заказы на два списка
                final activeOrders = orderProvider.userOrders.where((o) =>
                o.status != OrderStatus.completed &&
                    o.status != OrderStatus.cancelled
                ).toList();

                final pastOrders = orderProvider.userOrders.where((o) =>
                o.status == OrderStatus.completed ||
                    o.status == OrderStatus.cancelled
                ).toList();

                return TabBarView(
                  children: [
                    _buildOrderList(activeOrders, 'Нет активных заказов', 'Самое время подкрепиться!'),
                    _buildOrderList(pastOrders, 'История заказов пуста', 'Здесь будут ваши завершенные заказы'),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, String emptyTitle, String emptySubtitle) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView( // ListView нужен для работы RefreshIndicator даже когда пусто
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(emptyTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(emptySubtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return OrderCard(order: orders[index]);
        },
      ),
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      appBar: AppBar(title: const Text('История'), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: const Center(child: Text('Войдите в аккаунт')),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(child: Text('Ошибка: $error'));
  }
}