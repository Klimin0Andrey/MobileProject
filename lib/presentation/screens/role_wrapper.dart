import 'package:flutter/material.dart';
import 'package:linux_test2/presentation/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
// import 'package:linux_test2/presentation/screens/guest/guest_home.dart';
// import 'package:linux_test2/presentation/screens/customer/customer_home.dart';
import 'package:linux_test2/presentation/screens/admin/admin_home.dart';
import 'package:linux_test2/presentation/screens/courier/courier_home.dart';

class RoleBasedWrapper extends StatelessWidget {
  const RoleBasedWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    // Если пользователь не авторизован - показываем HomeScreen (там уже есть гостевая логика)
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
        return const HomeScreen(); // Customer тоже использует HomeScreen с табами
    }
  }
}