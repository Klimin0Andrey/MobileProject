// lib/presentation/screens/role_wrapper.dart

import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/theme_provider.dart';
import 'package:linux_test2/presentation/screens/admin/admin_home.dart';
import 'package:linux_test2/presentation/screens/courier/courier_home.dart';
import 'package:linux_test2/presentation/screens/home_screen.dart';
import 'package:provider/provider.dart';

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
        // ✅ ИЗМЕНЕНИЕ: Передаем UID пользователя для загрузки его темы
        themeProvider.loadUserTheme(user.uid);
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
}