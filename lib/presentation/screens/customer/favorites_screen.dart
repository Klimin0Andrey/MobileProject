import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/services/database.dart';
import 'package:linux_test2/presentation/widgets/restaurant_card.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';
import 'package:linux_test2/presentation/screens/home_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    if (user == null) {
      return _buildGuestView(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранные рестораны'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: DatabaseService(uid: user.uid).favoriteRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return RestaurantCard(
                restaurant: favorites[index],
                isGuest: false,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранные рестораны'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Войдите в аккаунт',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Чтобы сохранять рестораны в избранное, необходимо авторизоваться',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Навигация на экран авторизации
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const Authenticate(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Войти в аккаунт'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Возврат на главную страницу
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                        (route) => false,
                  );
                },
                child: const Text(
                  'Вернуться на главную',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Пока пусто',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Добавляйте рестораны в избранное, нажимая на сердечко в карточке',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Навигация на главную страницу с ресторанами
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                      (route) => false,
                );
              },
              icon: const Icon(Icons.restaurant),
              label: const Text('Перейти к ресторанам'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Альтернативный способ навигации - просто назад
                Navigator.of(context).pop();
              },
              child: const Text(
                'Вернуться назад',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}