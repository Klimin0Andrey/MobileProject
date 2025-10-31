import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/presentation/screens/customer/order_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    // Если пользователь не авторизован (гость)
    if (user == null) {
      return _buildGuestProfile(context);
    }

    return _buildUserProfile(context, user);
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Вы не авторизованы',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Войдите, чтобы получить доступ к истории заказов и настройкам профиля',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Навигация на экран авторизации
                  // Нужно будет добавить правильный путь
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Войти в аккаунт'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, AppUser user) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      children: [
        // Блок с информацией пользователя
        Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange.shade100,
              child: Text(
                _getUserInitials(user),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.email.split('@').first, // Берем имя из email до @
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Divider(),

        // Меню профиля
        _buildProfileMenuItem(
          icon: Icons.history,
          title: 'История заказов',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
            );
          },
        ),
        _buildProfileMenuItem(
          icon: Icons.location_on,
          title: 'Мои адреса',
          onTap: () {
            _showComingSoonDialog(context, 'Управление адресами');
          },
        ),
        _buildProfileMenuItem(
          icon: Icons.favorite,
          title: 'Избранные рестораны',
          onTap: () {
            _showComingSoonDialog(context, 'Избранные рестораны');
          },
        ),
        _buildProfileMenuItem(
          icon: Icons.notifications,
          title: 'Уведомления',
          onTap: () {
            _showComingSoonDialog(context, 'Настройки уведомлений');
          },
        ),
        _buildProfileMenuItem(
          icon: Icons.dark_mode,
          title: 'Тёмная тема',
          onTap: () {
            _showComingSoonDialog(context, 'Переключение темы');
          },
        ),
        _buildProfileMenuItem(
          icon: Icons.help,
          title: 'Помощь и поддержка',
          onTap: () {
            _showComingSoonDialog(context, 'Помощь и поддержка');
          },
        ),

        const Divider(),
        const SizedBox(height: 16),

        // Кнопка выхода
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: OutlinedButton(
            onPressed: () => _showLogoutDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, size: 20),
                SizedBox(width: 8),
                Text('Выйти из аккаунта', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  String _getUserInitials(AppUser user) {
    final emailName = user.email.split('@').first;
    if (emailName.length >= 2) {
      return emailName.substring(0, 2).toUpperCase();
    }
    return 'П'; // По умолчанию, если email очень короткий
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скоро будет доступно'),
        content: Text('Функция "$feature" находится в разработке'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthService().signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
