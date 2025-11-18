// lib/presentation/screens/customer/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/presentation/screens/customer/order_history_screen.dart';
import 'package:linux_test2/presentation/providers/theme_provider.dart';
import 'package:linux_test2/presentation/screens/customer/support_screen.dart';
import 'package:linux_test2/presentation/screens/customer/favorites_screen.dart';
import 'package:linux_test2/presentation/screens/customer/addresses_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
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
                  // ✅ ИСПРАВЛЕНО: Добавлена навигация на экран аутентификации
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
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, AppUser user) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      children: [
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
              user.name.isNotEmpty ? user.name : user.email.split('@').first,
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
        _buildProfileMenuItem(
          icon: Icons.history,
          title: 'История заказов',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
          ),
        ),
        _buildProfileMenuItem(
          icon: Icons.location_on,
          title: 'Мои адреса',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddressesScreen()),
          ),
        ),
        _buildProfileMenuItem(
          icon: Icons.favorite,
          title: 'Избранные рестораны',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const FavoritesScreen()),
          ),
        ),
        _buildProfileMenuItem(
          icon: Icons.notifications,
          title: 'Уведомления',
          onTap: () => _showComingSoonDialog(context, 'Настройки уведомлений'),
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Colors.orange,
              ),
              title: const Text('Тёмная тема'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(user.uid),
                activeColor: Colors.orange,
              ),
            );
          },
        ),
        _buildProfileMenuItem(
          icon: Icons.help,
          title: 'Помощь и поддержка',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SupportScreen()),
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),
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
    if (user.name.isNotEmpty) {
      return user.name.substring(0, 1).toUpperCase();
    }
    return user.email.substring(0, 1).toUpperCase();
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
    final authService = Provider.of<AuthService>(context, listen: false);

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
              // ✅ ИЗМЕНЕНИЕ: Просто выходим из аккаунта.
              // RoleWrapper сам позаботится о смене темы на гостевую.
              Navigator.of(context).pop();
              await authService.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
