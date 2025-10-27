import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/presentation/screens/guest/restaurant_detail.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isGuest;

  const RestaurantCard({super.key, required this.restaurant, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(restaurant: restaurant, isGuest: isGuest),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
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
              child: restaurant.imageUrl.isEmpty
                  ? const Icon(Icons.restaurant, size: 50, color: Colors.grey)
                  : null,
            ),
      
            // Информация о ресторане
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Рейтинг
                      Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(restaurant.rating.toStringAsFixed(1)),
                      const SizedBox(width: 16),
                      // Время доставки
                      Icon(Icons.access_time, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(restaurant.deliveryTime),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Типы кухни
                  Wrap(
                    spacing: 8,
                    children: restaurant.cuisineType.map((cuisine) {
                      return Chip(
                        label: Text(cuisine),
                        backgroundColor: Colors.orange[50],
                        labelStyle: const TextStyle(fontSize: 12),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}