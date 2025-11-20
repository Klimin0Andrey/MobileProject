// lib/presentation/screens/customer/profile_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';
import 'package:linux_test2/services/image_service.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/presentation/screens/customer/order_history_screen.dart';
import 'package:linux_test2/presentation/providers/theme_provider.dart';
import 'package:linux_test2/presentation/screens/customer/support_screen.dart';
import 'package:linux_test2/presentation/screens/customer/favorites_screen.dart';
import 'package:linux_test2/presentation/screens/customer/addresses_screen.dart';
import 'package:linux_test2/presentation/screens/customer/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// ✅ Добавляем 'with WidgetsBindingObserver' для отслеживания жизненного цикла приложения
class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker(); // Создаем один экземпляр ImagePicker

  // --- БЛОК ДЛЯ ВОССТАНОВЛЕНИЯ ПОТЕРЯННЫХ ДАННЫХ ---

  @override
  void initState() {
    super.initState();
    // Подписываемся на события жизненного цикла приложения (уход в фон, возврат)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Отписываемся, чтобы избежать утечек памяти
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Этот метод будет вызван, когда приложение вернется из фона
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Пытаемся восстановить данные, если они были потеряны
      _retrieveLostData();
    }
  }

  // Метод для восстановления изображения, если приложение было "убито" системой
  Future<void> _retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty || response.file == null) {
      return;
    }

    final user = context.read<AppUser?>();
    if (user != null) {
      print('✅ Изображение восстановлено после сбоя. Начинаем загрузку...');
      // Если данные были найдены, запускаем тот же процесс загрузки
      await _uploadImage(response.file!, user);
    }
  }
  // --- КОНЕЦ БЛОКА ---

  // Метод, который вызывается при нажатии на кнопку редактирования аватара
  Future<void> _pickAndUploadImage(AppUser user) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      // Вызываем наш централизованный метод загрузки
      await _uploadImage(image, user);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе фото: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Централизованный метод для самой загрузки (используется и при выборе, и при восстановлении)
  Future<void> _uploadImage(XFile image, AppUser user) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final imageService = ImageService();
      await imageService.uploadAvatarAsBase64(imageFile: image, uid: user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фото профиля успешно обновлено!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке фото: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Остальные методы и виджеты ---

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Камера'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (avatarUrl.startsWith('data:image')) {
      return MemoryImage(base64Decode(avatarUrl.split(',').last));
    }
    return NetworkImage(avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    if (user == null || user.uid.isEmpty) {
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
            const Text('Вы не авторизованы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Войдите, чтобы получить доступ к истории заказов и настройкам профиля', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const Authenticate())),
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
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            children: [
              _buildAvatarSection(user),
              const SizedBox(height: 16),
              Text(
                user.name.isNotEmpty ? user.name : user.email.split('@').first,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              // ✅ ДОБАВЬТЕ ЭТОТ БЛОК
              _buildProfileMenuItem(
                icon: Icons.manage_accounts_outlined,
                title: 'Настройки профиля',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      // Мы создадим этот экран на следующем шаге
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildProfileMenuItem(
                  icon: Icons.history,
                  title: 'История заказов',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OrderHistoryScreen()))),
              _buildProfileMenuItem(
                  icon: Icons.location_on,
                  title: 'Мои адреса',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddressesScreen()))),
              _buildProfileMenuItem(
                  icon: Icons.favorite,
                  title: 'Избранные рестораны',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const FavoritesScreen()))),
              _buildProfileMenuItem(
                  icon: Icons.notifications,
                  title: 'Уведомления',
                  onTap: () => _showComingSoonDialog(context, 'Настройки уведомлений')),
              Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) => ListTile(
                      leading: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.orange),
                      title: const Text('Тёмная тема'),
                      trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) => themeProvider.toggleTheme(user.uid),
                          activeColor: Colors.orange))),
              _buildProfileMenuItem(
                  icon: Icons.help,
                  title: 'Помощь и поддержка',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SupportScreen()))),
              const Divider(),
              const SizedBox(height: 16),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: OutlinedButton(
                      onPressed: () => _showLogoutDialog(context),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text('Выйти из аккаунта', style: TextStyle(fontSize: 16))
                          ]))),
            ],
          ),
          if (_isLoading)
            Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: Colors.orange))),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(AppUser user) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            key: ValueKey(user.avatarUrl ?? ''),
            radius: 50,
            backgroundColor: Colors.orange.shade100,
            backgroundImage: _getAvatarImage(user.avatarUrl),
            child: user.avatarUrl == null
                ? Text(user.initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.orange, width: 2)),
                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                        onTap: () => _pickAndUploadImage(user),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.edit, size: 20, color: Colors.orange))))),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap);
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
                  child: const Text('ОК'))
            ]));
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
                  child: const Text('Отмена')),
              TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await authService.signOut();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Выйти'))
            ]));
  }
}