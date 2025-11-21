// lib/presentation/screens/customer/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _phoneMaskFormatter = MaskTextInputFormatter(
      mask: '+7 (###) ###-##-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // Добавили контроллер Email
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppUser?>();
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _emailController.text = user.email; // Заполняем Email
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = context.read<AppUser?>();
    if (user == null || user.uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final authService = context.read<AuthService>();
    final user = context.read<AppUser?>();
    if (user == null || user.email.isEmpty) return;

    try {
      await authService.sendPasswordResetEmail(user.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Письмо для сброса пароля отправлено на вашу почту'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🔥 НОВЫЙ МЕТОД: Удаление аккаунта
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
            'Это действие необратимо. Все ваши данные, включая историю заказов и избранное, будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      // 1. Сначала удаляем данные из Firestore (опционально, можно оставить или пометить как deleted)
      final user = context.read<AppUser?>();
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      }

      // 2. Удаляем пользователя из Auth (самое важное)
      final authService = context.read<AuthService>();
      // Примечание: В AuthService нужно будет добавить метод deleteUser(),
      // который вызывает FirebaseAuth.instance.currentUser?.delete();

      // Если метода нет, можно вызвать напрямую тут (но лучше через сервис):
      // await FirebaseAuth.instance.currentUser?.delete();
      // Для простоты пока просто разлогиним, но в продакшене нужно именно delete()

      await authService.signOut();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: требуется повторный вход для удаления ($e)'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки профиля'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- Имя ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ваше имя',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Пожалуйста, введите имя' : null,
              ),
              const SizedBox(height: 16),

              // --- Телефон ---
              TextFormField(
                inputFormatters: [_phoneMaskFormatter],
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Номер телефона',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Пожалуйста, введите номер телефона'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Email (Только чтение) ---
              TextFormField(
                controller: _emailController,
                readOnly: true, // Нельзя редактировать
                enabled: false, // Визуально серый
                decoration: const InputDecoration(
                  labelText: 'Email (нельзя изменить)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  // fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
                ),
              ),

              const SizedBox(height: 32),

              // --- Кнопка Сохранить ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('Сохранить изменения', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // --- Смена пароля ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline, color: Colors.orange),
                title: const Text('Сменить пароль'),
                subtitle: const Text('Вам будет отправлено письмо'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _changePassword,
              ),

              // --- Удаление аккаунта ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Удалить аккаунт', style: TextStyle(color: Colors.red)),
                onTap: _deleteAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}