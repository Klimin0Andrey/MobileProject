import 'package:flutter_test/flutter_test.dart';
import 'package:linux_test2/data/models/dish.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';

void main() {
  late CartProvider cartProvider;
  late Dish testDish;

  // Этот код выполняется перед каждым тестом
  setUp(() {
    cartProvider = CartProvider();
    testDish = Dish(
      id: 'd1',
      name: 'Test Pizza',
      description: 'Delicious',
      price: 500.0,
      imageUrl: '',
      category: 'Pizza',
      restaurantId: 'r1',
      isAvailable: true,
    );
  });

  group('CartProvider Logic', () {
    test('Initial state should be empty', () {
      expect(cartProvider.items.isEmpty, true);
      expect(cartProvider.totalPrice, 0.0);
      expect(cartProvider.totalItems, 0);
    });

    test('addToCart adds item and updates total price', () {
      cartProvider.addToCart(testDish);

      expect(cartProvider.items.length, 1);
      expect(cartProvider.totalPrice, 500.0);
      expect(cartProvider.totalItems, 1);
    });

    test('addToCart twice increments quantity, not list length', () {
      cartProvider.addToCart(testDish);
      cartProvider.addToCart(testDish);

      expect(cartProvider.items.length, 1); // Все еще 1 позиция в списке
      expect(cartProvider.items.first.quantity, 2); // Но количество = 2
      expect(cartProvider.totalPrice, 1000.0); // 500 * 2
    });

    test('decrementQuantity reduces count and removes item if 0', () {
      cartProvider.addToCart(testDish); // qty = 1
      cartProvider.addToCart(testDish); // qty = 2

      cartProvider.decrementQuantity(testDish.id); // qty = 1
      expect(cartProvider.items.first.quantity, 1);

      cartProvider.decrementQuantity(testDish.id); // qty = 0 -> remove
      expect(cartProvider.items.isEmpty, true);
    });

    test('clearCart removes everything', () {
      cartProvider.addToCart(testDish);
      cartProvider.clearCart();

      expect(cartProvider.items.isEmpty, true);
      expect(cartProvider.totalPrice, 0.0);
    });
  });
}