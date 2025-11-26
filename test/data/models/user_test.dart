import 'package:flutter_test/flutter_test.dart';
import 'package:linux_test2/data/models/user.dart'; // Твой путь

void main() {
  group('AppUser Tests', () {
    test('fromMap creates valid user from JSON', () {
      // Имитируем данные, которые приходят из Firestore
      final Map<String, dynamic> json = {
        'uid': 'user123',
        'email': 'test@test.com',
        'role': 'customer',
        'name': 'Ivan',
        'phone': '+79990000000',
        'favorites': ['dish1', 'dish2'],
        'addresses': [] // Пустой список адресов
      };

      final user = AppUser.fromMap(json);

      expect(user.uid, 'user123');
      expect(user.email, 'test@test.com');
      expect(user.favorites.length, 2);
      expect(user.isCustomer, true); // Проверяем extension метод
    });
  });
}