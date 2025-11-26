import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/data/models/dish.dart';
import 'package:linux_test2/presentation/widgets/dish_card.dart';

void main() {
  testWidgets('Интеграционный тест: Добавление товара обновляет корзину', (WidgetTester tester) async {
    // 1. Подготовка данных
    final cartProvider = CartProvider();
    final dish = Dish(
      id: 'd1',
      name: 'Test Burger',
      description: 'Test Desc',
      price: 100.0,
      imageUrl: '',
      category: 'Food',
      restaurantId: 'r1',
      isAvailable: true,
    );

    // 2. Запускаем тестовое приложение с Провайдером
    await tester.pumpWidget(
      ChangeNotifierProvider<CartProvider>.value(
        value: cartProvider,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Рисуем карточку товара
                DishCard(dish: dish),
                // Рисуем "Виджет корзины" (просто текст для проверки)
                Consumer<CartProvider>(
                  builder: (context, cart, _) => Text('Итого: ${cart.totalPrice}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 3. Проверяем начальное состояние (Итого: 0.0)
    expect(find.text('Итого: 0.0'), findsOneWidget);

    // 4. Нажимаем кнопку "Добавить" на карточке
    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    await tester.pump(); // Ждем перерисовки

    // 5. ПРОВЕРКА ИНТЕГРАЦИИ:
    // Нажатие в одном виджете (Card) должно обновить другой виджет (Text) через Provider
    expect(find.text('Итого: 100.0'), findsOneWidget);
  });
}