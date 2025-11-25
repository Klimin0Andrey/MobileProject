import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linux_test2/services/image_service.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/presentation/providers/theme_provider.dart';
import 'package:linux_test2/presentation/widgets/universal_image.dart';
import 'package:linux_test2/presentation/screens/customer/edit_profile_screen.dart';
import 'package:linux_test2/presentation/screens/customer/notifications_screen.dart';

import 'package:linux_test2/presentation/screens/admin/admin_analytics_screen.dart';
import 'package:linux_test2/presentation/screens/admin/admin_users_screen.dart';
import 'package:linux_test2/presentation/screens/admin/admin_broadcast_screen.dart';  // ✅ ДОБАВЛЕНО

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // ---------------------------------------------------------------------------
  // 🟢 СТАРАЯ (ПРОВЕРЕННАЯ) ЛОГИКА
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retrieveLostData();
    }
  }

  Future<void> _retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty || response.file == null) {
      return;
    }

    if (!mounted) return;
    final user = context.read<AppUser?>();
    if (user != null) {
      await _uploadImage(response.file!, user);
    }
  }

  Future<void> _pickAndUploadImage(AppUser user) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      await _uploadImage(image, user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка при выборе фото: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadImage(XFile image, AppUser user) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final imageService = ImageService();
      await imageService.uploadAvatar(imageFile: image, uid: user.uid);

      // Задержка для синхронизации, как в старой версии
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фото профиля успешно обновлено!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {}); // Принудительное обновление
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка при загрузке фото: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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

  // ---------------------------------------------------------------------------
  // 🎨 НОВЫЙ ДИЗАЙН (UI)
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (user == null || user.uid.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('Ошибка: пользователь не найден')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль администратора'),
      ),
      // Используем Stack, чтобы сохранить функционал блокировки экрана при загрузке (как в старом)
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Секция Аватара (Новый стиль)
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _pickAndUploadImage(user),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: Colors.orange, width: 3),
                              ),
                              child: ClipOval(
                                child: UniversalImage(
                                  imageUrl: user.avatarUrl ?? '',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorWidget: Center(
                                    child: Text(
                                      user.initials,
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name.isNotEmpty
                            ? user.name
                            : user.email.split('@').first,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Администратор',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Секция "Администрирование" (Новый функционал в новом дизайне)
                Text(
                  'Администрирование',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Кнопка Аналитика
                _buildAdminMenuItem(
                  context: context,
                  icon: Icons.analytics,
                  title: 'Аналитика',
                  subtitle: 'Статистика и графики',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminAnalyticsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Кнопка Пользователи
                _buildAdminMenuItem(
                  context: context,
                  icon: Icons.people,
                  title: 'Управление пользователями',
                  subtitle: 'Клиенты и сотрудники',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminUsersScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // 3. Секция "Настройки профиля" (Новый дизайн)
                Text(
                  'Настройки профиля',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildListTile(
                  context,
                  icon: Icons.edit,
                  title: 'Редактировать профиль',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfileScreen()),
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.notifications,
                  title: 'Уведомления и рассылка',  // ✅ ИЗМЕНЕНО: переименовано
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()),
                  ),
                ),
                // ✅ УДАЛЕНО: Пункт "Поддержка" убран

                // Переключатель темы
                SwitchListTile(
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Colors.orange,
                  ),
                  title: const Text('Темная тема'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(user.uid),
                  activeColor: Colors.orange,
                ),

                const SizedBox(height: 24),

                // 4. Кнопка Выход (Новый дизайн + Старая логика внутри)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Оверлей загрузки (из старого дизайна, но адаптирован)
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),  // ✅ ИСПРАВЛЕНО: withOpacity → withValues
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.orange)),
            ),
        ],
      ),
    );
  }

  // Вспомогательный метод для красивых карточек админки
  Widget _buildAdminMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),  // ✅ ИСПРАВЛЕНО: withOpacity → withValues
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // Вспомогательный метод для простых пунктов меню
  Widget _buildListTile(BuildContext context,
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      trailing:
      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Логика выхода (совмещена: дизайн диалога из нового, но процесс выхода надежный)
  Future<void> _handleLogout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await authService.signOut();
      // Дополнительная навигация не нужна, authService.signOut() обычно триггерит authStateChanges
      // и wrapper перебрасывает на экран логина автоматически.
    }
  }
}