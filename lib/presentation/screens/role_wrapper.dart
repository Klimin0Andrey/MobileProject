// lib/presentation/screens/role_wrapper.dart

import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/theme_provider.dart';
import 'package:linux_test2/presentation/screens/admin/admin_home.dart';
import 'package:linux_test2/presentation/screens/courier/courier_home.dart';
import 'package:linux_test2/presentation/screens/home_screen.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleBasedWrapper extends StatelessWidget {
  const RoleBasedWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user == null) {
        themeProvider.setGuestMode();
      } else {
        themeProvider.loadUserTheme(user.uid);

        // ✅ ДОБАВЛЕНО: Проверка бана при загрузке
        _checkBanStatus(context, user.uid);
      }
    });

    if (user == null) {
      return const HomeScreen();
    }

    switch (user.role) {
      case 'admin':
        return const AdminHome();
      case 'courier':
        return const CourierHome();
      case 'customer':
      default:
        return const HomeScreen();
    }
  }

  // ✅ ДОБАВЛЕНО: Проверка статуса бана
  Future<void> _checkBanStatus(BuildContext context, String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final isBanned = userDoc.data()?['isBanned'] as bool? ?? false;

      if (isBanned) {
        final authService = AuthService();
        await authService.signOut();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ваш аккаунт заблокирован. Обратитесь в поддержку.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Ошибка проверки бана: $e');
    }
  }
}