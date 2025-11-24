import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/order.dart' as app_order;

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить выручку за период
  Future<double> getRevenueByPeriod(DateTime start, DateTime end) async {
    try {
      final startTimestamp = Timestamp.fromDate(start);
      final endTimestamp = Timestamp.fromDate(end);

      final snapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThanOrEqualTo: endTimestamp)
          .where('status', isEqualTo: 'completed') // Только завершенные заказы
          .get();

      double totalRevenue = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += totalPrice;
      }

      return totalRevenue;
    } catch (e) {
      print('❌ Ошибка получения выручки: $e');
      return 0.0;
    }
  }

  /// Получить количество заказов за период
  Future<int> getOrdersCountByPeriod(DateTime start, DateTime end) async {
    try {
      final startTimestamp = Timestamp.fromDate(start);
      final endTimestamp = Timestamp.fromDate(end);

      final snapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThanOrEqualTo: endTimestamp)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Ошибка получения количества заказов: $e');
      return 0;
    }
  }

  /// Получить топ популярных блюд
  Future<List<Map<String, dynamic>>> getTopDishes({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('orders');

      // Фильтр по дате, если указан
      if (startDate != null && endDate != null) {
        query = query
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      // Подсчитываем количество каждого блюда
      final Map<String, Map<String, dynamic>> dishCounts = {};

      for (var doc in snapshot.docs) {
        // ✅ ИСПРАВЛЕНИЕ: Явное приведение типа к Map<String, dynamic>
        final data = doc.data() as Map<String, dynamic>;

        // Теперь Dart знает, что у data есть ключи, и ошибки не будет
        final items = data['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final dishId = item['dishId'] as String? ?? '';
          final dishName = item['dishName'] as String? ?? 'Неизвестное блюдо';
          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;

          if (dishId.isNotEmpty) {
            if (dishCounts.containsKey(dishId)) {
              dishCounts[dishId]!['quantity'] += quantity;
              dishCounts[dishId]!['revenue'] += price * quantity;
            } else {
              dishCounts[dishId] = {
                'dishId': dishId,
                'dishName': dishName,
                'quantity': quantity,
                'revenue': price * quantity,
              };
            }
          }
        }
      }

      // Сортируем по количеству и берем топ
      final topDishes = dishCounts.values.toList()
        ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      return topDishes.take(limit).toList();
    } catch (e) {
      print('❌ Ошибка получения топ блюд: $e');
      return [];
    }
  }

  /// Получить данные для графика выручки (по дням)
  Future<List<Map<String, dynamic>>> getRevenueChartData(
      DateTime start,
      DateTime end,
      ) async {
    try {
      final startTimestamp = Timestamp.fromDate(start);
      final endTimestamp = Timestamp.fromDate(end);

      final snapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThanOrEqualTo: endTimestamp)
          .where('status', isEqualTo: 'completed')
          .get();

      // Группируем по дням
      final Map<String, double> dailyRevenue = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;

        if (createdAt != null) {
          final dayKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0.0) + totalPrice;
        }
      }

      // Преобразуем в список для графика
      final List<Map<String, dynamic>> chartData = [];
      final sortedKeys = dailyRevenue.keys.toList()..sort();

      for (int i = 0; i < sortedKeys.length; i++) {
        chartData.add({
          'day': sortedKeys[i],
          'revenue': dailyRevenue[sortedKeys[i]]!,
          'index': i.toDouble(),
        });
      }

      return chartData;
    } catch (e) {
      print('❌ Ошибка получения данных графика: $e');
      return [];
    }
  }

  /// Получить статистику за сегодня
  Future<Map<String, dynamic>> getTodayStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final revenue = await getRevenueByPeriod(startOfDay, endOfDay);
    final ordersCount = await getOrdersCountByPeriod(startOfDay, endOfDay);

    return {
      'revenue': revenue,
      'ordersCount': ordersCount,
    };
  }

  /// Получить статистику за неделю
  Future<Map<String, dynamic>> getWeekStats() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));

    final revenue = await getRevenueByPeriod(startOfWeekDay, endOfWeek);
    final ordersCount = await getOrdersCountByPeriod(startOfWeekDay, endOfWeek);

    return {
      'revenue': revenue,
      'ordersCount': ordersCount,
    };
  }

  /// Получить статистику за месяц
  Future<Map<String, dynamic>> getMonthStats() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final revenue = await getRevenueByPeriod(startOfMonth, endOfMonth);
    final ordersCount = await getOrdersCountByPeriod(startOfMonth, endOfMonth);

    return {
      'revenue': revenue,
      'ordersCount': ordersCount,
    };
  }
}