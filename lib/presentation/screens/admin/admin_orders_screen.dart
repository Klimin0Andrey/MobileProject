import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;
import 'package:linux_test2/presentation/providers/admin_order_provider.dart';
import 'package:linux_test2/presentation/screens/customer/order_details_screen.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление заказами'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: isDark ? Colors.white : Colors.white,
          labelColor: isDark ? Colors.white : Colors.white,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(
              icon: Icon(Icons.new_releases),
              text: 'Новые',
            ),
            Tab(
              icon: Icon(Icons.restaurant),
              text: 'Готовятся',
            ),
            Tab(
              icon: Icon(Icons.delivery_dining),
              text: 'В доставке',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Завершены',
            ),
            Tab(
              icon: Icon(Icons.cancel),
              text: 'Отменены',
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<app_order.Order>>(
        // 1. Слушаем поток всех заказов
        stream: Provider.of<AdminOrderProvider>(context, listen: false).getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          // 2. Получаем список заказов из Firestore
          final allOrders = snapshot.data ?? [];
          final provider = Provider.of<AdminOrderProvider>(context, listen: false);

          return TabBarView(
            controller: _tabController,
            children: [
              // 3. ✅ ИСПРАВЛЕНО: Используем filterOrdersByStatus и передаем список allOrders
              _buildOrdersList(
                provider.filterOrdersByStatus(allOrders, app_order.OrderStatus.pending),
                'Новые заказы',
              ),
              _buildOrdersList(
                provider.filterOrdersByStatus(allOrders, app_order.OrderStatus.processing),
                'Заказы в приготовлении',
              ),
              _buildOrdersList(
                provider.filterOrdersByStatus(allOrders, app_order.OrderStatus.delivering),
                'Заказы в доставке',
              ),
              _buildOrdersList(
                provider.filterOrdersByStatus(allOrders, app_order.OrderStatus.completed),
                'Завершенные заказы',
              ),
              _buildOrdersList(
                provider.filterOrdersByStatus(allOrders, app_order.OrderStatus.cancelled),
                'Отмененные заказы',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<app_order.Order> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildOrderCard(app_order.Order order) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Заказ #${order.id?.substring(0, 8) ?? '...'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '📍 ${order.deliveryAddressString}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '📦 ${order.items.length} позиций',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '💰 ${order.totalPrice.toStringAsFixed(2)} ₽',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '⏰ ${dateFormat.format(order.createdAt.toDate())}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (order.status == app_order.OrderStatus.pending ||
                  order.status == app_order.OrderStatus.processing) ...[
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.status == app_order.OrderStatus.pending)
                      TextButton.icon(
                        onPressed: () => _acceptOrder(order.id!),
                        icon: const Icon(Icons.check),
                        label: const Text('Принять'),
                      ),
                    if (order.status == app_order.OrderStatus.pending ||
                        order.status == app_order.OrderStatus.processing)
                      TextButton.icon(
                        onPressed: () => _showCancelDialog(order),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('Отменить', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return Colors.orange;
      case app_order.OrderStatus.processing:
        return Colors.blue;
      case app_order.OrderStatus.delivering:
        return Colors.deepPurple;
      case app_order.OrderStatus.completed:
        return Colors.green;
      case app_order.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return 'Новый';
      case app_order.OrderStatus.processing:
        return 'Готовится';
      case app_order.OrderStatus.delivering:
        return 'В доставке';
      case app_order.OrderStatus.completed:
        return 'Завершен';
      case app_order.OrderStatus.cancelled:
        return 'Отменен';
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await Provider.of<AdminOrderProvider>(context, listen: false)
          .acceptOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ принят')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _showCancelDialog(app_order.Order order) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заказ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите причину отмены:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Причина отмены',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context, reasonController.text);
              }
            },
            child: const Text('Отменить заказ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await Provider.of<AdminOrderProvider>(context, listen: false)
            .cancelOrder(order.id!, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Заказ отменен')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }
}


