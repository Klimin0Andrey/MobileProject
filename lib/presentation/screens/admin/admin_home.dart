import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/screens/admin/admin_orders_screen.dart';
import 'package:linux_test2/presentation/screens/admin/admin_support_screen.dart';
import 'package:linux_test2/presentation/screens/admin/admin_menu_screen.dart';
import 'package:linux_test2/presentation/screens/admin/admin_users_screen.dart';
import 'package:linux_test2/presentation/screens/admin/admin_profile_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminOrdersScreen(),
    const AdminSupportScreen(),
    const AdminMenuScreen(),
    const AdminUsersScreen(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        actions: [
          // ✅ ДОБАВЛЕНО: Кнопка профиля
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProfileScreen(),
                ),
              );
            },
            tooltip: 'Профиль',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Поддержка',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Меню',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Пользователи',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
