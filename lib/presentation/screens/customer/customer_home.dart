import 'package:flutter/material.dart';
import 'package:linux_test2/services/auth.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🍕 ДОСТАВКА ЕДЫ - ПОЛЬЗОВАТЕЛЬ',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        actions: [
          // ВРЕМЕННАЯ кнопка выхода для тестирования
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await AuthService().signOut();
              // После выхода автоматически перейдем на GuestHome
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Вы авторизованы как ПОЛЬЗОВАТЕЛЬ',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Здесь будет главная страница для пользователей\nс ресторанами, корзиной и заказами',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}