import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/presentation/providers/restaurant_provider.dart';
import 'package:linux_test2/presentation/widgets/restaurant_card.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> cuisineTypes = ['Все', 'Итальянская', 'Азиатская', 'Фастфуд', 'Десерты'];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RestaurantProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Рестораны и кафе'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Consumer<RestaurantProvider>(
          builder: (context, restaurantProvider, child) {
            return Column(
              children: [
                // Поиск
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск ресторанов...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      restaurantProvider.searchRestaurants(value);
                    },
                  ),
                ),

                // Фильтры по кухне
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cuisineTypes.length,
                    itemBuilder: (context, index) {
                      final cuisine = cuisineTypes[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FilterChip(
                          label: Text(cuisine),
                          selected: restaurantProvider.selectedCuisine == cuisine,
                          onSelected: (selected) {
                            restaurantProvider.filterByCuisine(cuisine);
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Количество найденных ресторанов
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Найдено ресторанов: ${restaurantProvider.restaurants.length}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Список ресторанов
                Expanded(
                  child: restaurantProvider.restaurants.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Рестораны не найдены',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: restaurantProvider.restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurantProvider.restaurants[index];
                      return RestaurantCard(restaurant: restaurant);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}