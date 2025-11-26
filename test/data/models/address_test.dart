import 'package:flutter_test/flutter_test.dart';
import 'package:linux_test2/data/models/address.dart'; // Поменяй на свой путь импорта

void main() {
  group('DeliveryAddress Tests', () {
    // 1. Тест: Проверяем, что полный адрес собирается правильно
    test('fullAddress returns correctly formatted string with all fields', () {
      // ARRANGE (Подготовка)
      final address = DeliveryAddress(
        id: '1',
        title: 'Дом',
        address: 'ул. Пушкина 10',
        apartment: '5',
        entrance: '1',
        floor: '2',
        intercom: '123',
        isDefault: true,
        createdAt: DateTime.now(),
      );

      // ACT (Действие)
      final result = address.fullAddress;

      // ASSERT (Проверка)
      // Ожидаем: "ул. Пушкина 10, кв. 5, подъезд 1, этаж 2, домофон 123"
      expect(result, contains('ул. Пушкина 10'));
      expect(result, contains('кв. 5'));
      expect(result, contains('подъезд 1'));
    });

    // 2. Тест: Проверяем, что работает без доп. полей (только улица)
    test('fullAddress returns only street if other fields are null', () {
      final address = DeliveryAddress(
        id: '1',
        title: 'Работа',
        address: 'ул. Ленина 1',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      expect(address.fullAddress, 'ул. Ленина 1');
    });
  });
}