import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:linux_test2/services/analytics_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  String _selectedPeriod = 'Сегодня'; // 'Сегодня', 'Неделя', 'Месяц'
  bool _isLoading = true;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topDishes = [];
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> stats;
      DateTime startDate;
      DateTime endDate = DateTime.now();

      switch (_selectedPeriod) {
        case 'Сегодня':
          stats = await _analyticsService.getTodayStats();
          startDate = DateTime.now().subtract(const Duration(days: 1));
          break;
        case 'Неделя':
          stats = await _analyticsService.getWeekStats();
          startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'Месяц':
          stats = await _analyticsService.getMonthStats();
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        default:
          stats = await _analyticsService.getTodayStats();
          startDate = DateTime.now().subtract(const Duration(days: 1));
      }

      final topDishes = await _analyticsService.getTopDishes(
        limit: 10,
        startDate: startDate,
        endDate: endDate,
      );

      final chartData = await _analyticsService.getRevenueChartData(
        startDate,
        endDate,
      );

      if (mounted) {
        setState(() {
          _stats = stats;
          _topDishes = topDishes;
          _chartData = chartData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки аналитики: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        actions: [
          // Переключатель периода
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'Сегодня', child: Text('Сегодня')),
                DropdownMenuItem(value: 'Неделя', child: Text('Неделя')),
                DropdownMenuItem(value: 'Месяц', child: Text('Месяц')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPeriod = value);
                  _loadAnalytics();
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Карточки со статистикой
              _buildStatsCards(),
              const SizedBox(height: 24),

              // График выручки
              _buildRevenueChart(),
              const SizedBox(height: 24),

              // Топ блюд
              _buildTopDishes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final revenue = (_stats['revenue'] as num?)?.toDouble() ?? 0.0;
    final ordersCount = (_stats['ordersCount'] as int?) ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Выручка',
            value: '${NumberFormat('#,##0', 'ru_RU').format(revenue)} ₽',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Заказов',
            value: ordersCount.toString(),
            icon: Icons.shopping_bag,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    if (_chartData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Нет данных для графика',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выручка по дням',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _chartData.map((e) => e['revenue'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.orange,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _chartData.length) {
                            final day = _chartData[value.toInt()]['day'] as String;
                            final parts = day.split('-');
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${parts[2]}.${parts[1]}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _chartData.map((data) {
                    return BarChartGroupData(
                      x: (data['index'] as double).toInt(),
                      barRods: [
                        BarChartRodData(
                          toY: data['revenue'] as double,
                          color: Colors.orange,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDishes() {
    if (_topDishes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Нет данных о блюдах',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Топ популярных блюд',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._topDishes.asMap().entries.map((entry) {
              final index = entry.key;
              final dish = entry.value;
              return _TopDishItem(
                rank: index + 1,
                dishName: dish['dishName'] as String? ?? 'Неизвестное блюдо',
                quantity: dish['quantity'] as int? ?? 0,
                revenue: (dish['revenue'] as num?)?.toDouble() ?? 0.0,
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Виджет карточки статистики
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет элемента топа блюд
class _TopDishItem extends StatelessWidget {
  final int rank;
  final String dishName;
  final int quantity;
  final double revenue;

  const _TopDishItem({
    required this.rank,
    required this.dishName,
    required this.quantity,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Место
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.orange : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Название
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dishName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Заказано: $quantity раз',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Выручка
          Text(
            '${NumberFormat('#,##0', 'ru_RU').format(revenue)} ₽',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}