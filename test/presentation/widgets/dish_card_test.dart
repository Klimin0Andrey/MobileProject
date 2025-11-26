import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/dish.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/widgets/dish_card.dart';

void main() {
  testWidgets('DishCard displays info and adds to cart', (WidgetTester tester) async {
    // 1. Подготовка данных
    final dish = Dish(
      id: 'd1',
      name: 'Super Burger',
      description: 'Very tasty',
      price: 350.0,
      imageUrl: '', // Пустая ссылка, чтобы не грузить картинку в тесте
      category: 'Burgers',
      restaurantId: 'r1',
      isAvailable: true,
    );

    // 2. Создаем провайдер (он нужен виджету DishCard)
    final cartProvider = CartProvider();

    // 3. Загружаем виджет в тестовое окружение
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<CartProvider>.value(
            value: cartProvider,
            child: DishCard(dish: dish),
          ),
        ),
      ),
    );

    // 4. ПРОВЕРКИ ОТРИСОВКИ (UI)
    // Ищем текст с названием блюда
    expect(find.text('Super Burger'), findsOneWidget);
    // Ищем текст с ценой
    expect(find.text('350.0 ₽'), findsOneWidget);
    // Ищем иконку корзины
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);

    // 5. ПРОВЕРКА ДЕЙСТВИЯ (Нажатие)
    // Нажимаем на иконку корзины
    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    // Ждем анимацию SnackBar
    await tester.pump();

    // 6. Проверяем, что товар реально добавился в провайдер
    expect(cartProvider.items.length, 1);
    expect(cartProvider.items.first.dish.name, 'Super Burger');

    // Проверяем, что появился SnackBar
    expect(find.text('Super Burger добавлен в корзину'), findsOneWidget);
  });
}