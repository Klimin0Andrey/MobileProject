import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/screens/guest/restaurant_detail.dart';
import 'package:linux_test2/services/database.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isGuest;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    // Логика определения: показывать кнопку лайка или нет
    if (isGuest || user == null) {
      return _buildRestaurantCard(context, false, () {});
    }

    // Слушаем изменения в реальном времени
    return StreamBuilder<bool>(
      stream: DatabaseService(uid: user.uid).isRestaurantFavorite(restaurant.id),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return _buildRestaurantCard(
          context,
          isFavorite,
          // Передаем колбэк с логикой тогла
              () => _toggleFavorite(context, user.uid, isFavorite),
        );
      },
    );
  }

  Widget _buildRestaurantCard(
      BuildContext context,
      bool isFavorite,
      VoidCallback onFavoriteTap,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(
              restaurant: restaurant,
              isGuest: isGuest,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4, // Чуть приподняли карточку для красоты
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias, // Чтобы картинка не вылезала за скругления
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ УЛУЧШЕНИЕ 1: Hero анимация для картинки
                Hero(
                  tag: 'restaurant_image_${restaurant.id}', // Уникальный тег
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: restaurant.imageUrl.isNotEmpty
                        ? Image.network(
                      restaurant.imageUrl,
                      fit: BoxFit.cover,
                      // Плавное появление картинки
                      loadingBuilder: (ctx, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: Icon(Icons.image, color: Colors.white));
                      },
                      errorBuilder: (ctx, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    )
                        : const Center(child: Icon(Icons.restaurant, size: 50, color: Colors.grey)),
                  ),
                ),

                // Информация о ресторане
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Рейтинг справа от названия
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.green, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  restaurant.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        restaurant.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Нижняя строка: Время и Кухня
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.grey[500], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.deliveryTime,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          Text('•', style: TextStyle(color: Colors.grey[400])),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              restaurant.cuisineType.join(', '),
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Кнопка избранного
            if (!isGuest)
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // Анимация смены иконки (необязательно, но красиво)
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey<bool>(isFavorite),
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ УЛУЧШЕНИЕ 2: Добавляем визуальную обратную связь (SnackBar)
  void _toggleFavorite(BuildContext context, String userId, bool isCurrentlyFavorite) async {
    final database = DatabaseService(uid: userId);

    if (isCurrentlyFavorite) {
      await database.removeFromFavorites(restaurant.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${restaurant.name} удален из избранного'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    } else {
      await database.addToFavorites(restaurant.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${restaurant.name} добавлен в избранное'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}