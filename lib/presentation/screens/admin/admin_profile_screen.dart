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
import 'package:linux_test2/presentation/screens/customer/support_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

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
          SnackBar(content: Text('Ошибка при выборе фото: $e'), backgroundColor: Colors.red),
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

      // ✅ ДОБАВИТЬ: Небольшая задержка для синхронизации Firestore
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фото профиля успешно обновлено!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // ✅ ДОБАВИТЬ: Принудительно обновляем экран
        setState(() {});
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
  // Future<void> _uploadImage(XFile image, AppUser user) async {
  //   if (!mounted) return;
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final imageService = ImageService();
  //     await imageService.uploadAvatarAsBase64(imageFile: image, uid: user.uid);
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Фото профиля успешно обновлено!'), backgroundColor: Colors.green),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Ошибка при загрузке фото: $e'), backgroundColor: Colors.red),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    if (user == null || user.uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('Ошибка: пользователь не найден')));
    }

    // ✅ ДОБАВЛЕНО: Scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: _buildAdminProfile(context, user),
    );
  }

  Widget _buildAdminProfile(BuildContext context, AppUser user) {
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Stack(
        children: [
          // ✅ ДОБАВЛЕНО: Material для поддержки InkWell/ListTile
          Material(
            color: Colors.transparent,
            child: ListView(
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Администратор',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildProfileMenuItem(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Настройки профиля',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) => ListTile(
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
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.orange)),
            ),
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
            child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ? ClipOval(
              child: UniversalImage(
                imageUrl: user.avatarUrl!,
                width: 100,
                height: 100,
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
            )
                : Text(
              user.initials,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _pickAndUploadImage(user),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.edit, size: 20, color: Colors.orange),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
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
              // 1. Закрываем диалог
              Navigator.of(context).pop();

              // 2. Возвращаемся на главный экран админа (закрываем экран профиля)
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }

              // 3. Вызываем выход
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


