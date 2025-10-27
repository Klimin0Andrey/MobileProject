import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/presentation/screens/customer/cart_screen.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';

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
            Text('Вы авторизованы как ПОЛЬЗОВАТЕЛЬ'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: null,
              child: Text('Перейти в корзину'),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
            backgroundColor: Colors.orange,
            child: Stack(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                if (cartProvider.totalItems > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        cartProvider.totalItems.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}