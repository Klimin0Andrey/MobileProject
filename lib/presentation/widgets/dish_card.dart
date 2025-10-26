// presentation/widgets/dish_card.dart
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/dish.dart';

class DishCard extends StatelessWidget {
  final Dish dish;

  const DishCard({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Изображение блюда
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              image: dish.imageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(dish.imageUrl),
                fit: BoxFit.cover,
              )
                  : null,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 12),
          // Информация о блюде
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dish.description,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${dish.price} ₽',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Кнопка добавления в корзину
          IconButton(
            onPressed: () {
              // TODO: Добавить в корзину
            },
            icon: const Icon(Icons.add_shopping_cart),
          ),
        ],
      ),
    );
  }
}