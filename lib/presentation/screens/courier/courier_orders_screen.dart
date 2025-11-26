import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/courier_provider.dart';
import 'package:intl/intl.dart';

class CourierOrdersScreen extends StatefulWidget {
  const CourierOrdersScreen({super.key});

  @override
  State<CourierOrdersScreen> createState() => _CourierOrdersScreenState();
}

class _CourierOrdersScreenState extends State<CourierOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourierProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final courierProvider = Provider.of<CourierProvider>(context, listen: false);
    final user = Provider.of<AppUser?>(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Ошибка: пользователь не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные заказы'),
        actions: [
          Consumer<CourierProvider>(
            builder: (context, provider, _) {
              return Row(
                children: [
                  Text(
                    provider.isOnline ? 'Онлайн' : 'Офлайн',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Switch(
                    value: provider.isOnline,
                    onChanged: (value) async {
                      try {
                        await provider.toggleOnlineStatus();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка изменения статуса: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    // Настройки цветов свитча
                    thumbColor: const MaterialStatePropertyAll(Colors.white),
                    trackColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white.withOpacity(0.5);
                      }
                      return Colors.white.withOpacity(0.2);
                    }),
                    trackOutlineColor: const MaterialStatePropertyAll(Colors.transparent),
                  ),
                  const SizedBox(width: 12),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<app_order.Order>>(
        stream: courierProvider.getAvailableOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          // Используем Consumer для реактивного обновления при смене статуса
          final courierProviderStatus = Provider.of<CourierProvider>(context);

          if (!courierProviderStatus.isOnline) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Вы сейчас офлайн',
                    style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Включите статус "Онлайн" сверху,\nчтобы получать заказы',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Нет доступных заказов',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Заказы появятся здесь, когда ресторан\nначнет их готовить',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orders[index], user.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, app_order.Order order, String courierId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetails(context, order, courierId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Заказ #${order.id?.substring(0, 8) ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${order.totalPrice.toStringAsFixed(2)} ₽',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddressString,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.restaurant_menu, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${order.items.length} ${_getItemsText(order.items.length)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm').format(order.createdAt.toDate()),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              if (order.comment != null && order.comment!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.comment!,
                          style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _acceptOrder(context, order, courierId),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Принять заказ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getItemsText(int count) {
    if (count == 1) return 'блюдо';
    if (count >= 2 && count <= 4) return 'блюда';
    return 'блюд';
  }

  // ✅ ИСПРАВЛЕНО: Добавлен foregroundColor для кнопки, чтобы текст был виден
  Future<void> _acceptOrder(BuildContext context, app_order.Order order, String courierId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Адаптивный фон диалога
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Принять заказ?',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Вы уверены, что хотите принять заказ на сумму ${order.totalPrice.toStringAsFixed(2)} ₽?',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              // Серый цвет для кнопки отмены, чтобы не отвлекала
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              // ✅ ВАЖНО: Явно задаем белый цвет текста
              foregroundColor: Colors.white,
            ),
            child: const Text('Принять', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final courierProvider = Provider.of<CourierProvider>(context, listen: false);
        await courierProvider.acceptOrder(order.id!, courierId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заказ принят! Перейдите в "Мои заказы"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ✅ ИСПРАВЛЕНО: Адаптированы цвета текста под тему и кнопки
  Future<void> _showOrderDetails(BuildContext context, app_order.Order order, String courierId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey[300] : Colors.black87;
    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Заказ #${order.id?.substring(0, 8) ?? 'N/A'}',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.location_on, order.deliveryAddressString, textColor, labelColor),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.phone, order.phone, textColor, labelColor),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.payments, '${order.totalPrice.toStringAsFixed(2)} ₽', textColor, labelColor),

              Divider(height: 24, color: isDark ? Colors.grey[800] : Colors.grey[300]),

              Text('Состав заказа:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.dish.name} x ${item.quantity}',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                ),
              )),

              if (order.comment != null && order.comment!.isNotEmpty) ...[
                Divider(height: 24, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                Text('Комментарий:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Text(order.comment!, style: TextStyle(color: textColor)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Закрыть',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptOrder(context, order, courierId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white, // ✅ Белый текст
            ),
            child: const Text('Принять', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color? textColor, Color? iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? Colors.grey),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: textColor))),
      ],
    );
  }
}