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
      type: MaskAutoCompletionType.lazy
  );

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Заполняем поля текущими данными пользователя при открытии экрана
    final user = context.read<AppUser?>();
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Метод для сохранения изменений имени и телефона
  Future<void> _updateProfile() async {
    // Проверяем валидность формы
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = context.read<AppUser?>();
    if (user == null || user.uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    };

    try {
      // Обновляем данные напрямую в документе пользователя в Firestore
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Метод для отправки письма для сброса пароля
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
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ваше имя',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Пожалуйста, введите имя' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                inputFormatters: [_phoneMaskFormatter],
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Номер телефона',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Пожалуйста, введите номер телефона' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('Сохранить изменения', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline, color: Colors.orange),
                title: const Text('Сменить пароль'),
                subtitle: const Text('Вам будет отправлено письмо для восстановления'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _changePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}