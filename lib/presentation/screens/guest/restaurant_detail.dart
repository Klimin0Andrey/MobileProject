// presentation/screens/guest/restaurant_detail.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/presentation/providers/restaurant_provider.dart';
import 'package:linux_test2/presentation/widgets/dish_card.dart';
import 'package:linux_test2/data/models/dish.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
      ),
      body: Column(
        children: [
          // Header с изображением и информацией
          _buildRestaurantHeader(),
          // Меню ресторана
          _buildMenuSection(context),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        image: restaurant.imageUrl.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(restaurant.imageUrl),
          fit: BoxFit.cover,
        )
            : null,
        color: Colors.grey[300],
      ),
      child: Container(
        color: Colors.black54,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                restaurant.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                restaurant.description,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Expanded(
      child: StreamBuilder<List<Dish>>(
        stream: context.read<RestaurantProvider>().getRestaurantDishes(restaurant.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final dishes = snapshot.data ?? [];

          if (dishes.isEmpty) {
            return const Center(child: Text('Меню пока пусто'));
          }

          return ListView.builder(
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              return DishCard(dish: dishes[index]);
            },
          );
        },
      ),
    );
  }
}