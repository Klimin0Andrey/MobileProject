import 'package:flutter/material.dart';
import 'package:linux_test2/presentation/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/theme_provider.dart';
import 'package:linux_test2/presentation/screens/admin/admin_home.dart';
import 'package:linux_test2/presentation/screens/courier/courier_home.dart';

class RoleBasedWrapper extends StatefulWidget {
  const RoleBasedWrapper({super.key});

  @override
  State<RoleBasedWrapper> createState() => _RoleBasedWrapperState();
}

class _RoleBasedWrapperState extends State<RoleBasedWrapper> {
  @override
  void initState() {
    super.initState();
    // Устанавливаем гостевой режим при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final user = Provider.of<AppUser?>(context, listen: false);

      if (user == null) {
        themeProvider.enableGuestMode();
      } else {
        themeProvider.disableGuestMode();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Обновляем режим темы при изменении пользователя
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user == null && !themeProvider.isGuestMode) {
        themeProvider.enableGuestMode();
      } else if (user != null && themeProvider.isGuestMode) {
        themeProvider.disableGuestMode();
      }
    });

    // Если пользователь не авторизован - показываем HomeScreen
    if (user == null) {
      print('→ Showing HomeScreen (Guest mode)');
      return const HomeScreen();
    }

    // Для авторизованных пользователей - показываем соответствующий экран
    switch (user.role) {
      case 'admin':
        print('→ Showing AdminHome');
        return const AdminHome();
      case 'courier':
        print('→ Showing CourierHome');
        return const CourierHome();
      case 'customer':
      default:
        print('→ Showing HomeScreen (Customer mode)');
        return const HomeScreen();
    }
  }
}