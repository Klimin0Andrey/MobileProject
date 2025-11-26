import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/data/models/user.dart';

// 1. Создаем "Фейковый" сервис авторизации
// Он наследуется от Fake, чтобы не реализовывать все методы сразу
class FakeAuthService extends Fake implements AuthService {
  @override
  Stream<AppUser?> get user {
    // Возвращаем поток с null (как будто пользователь не вошел)
    return Stream.value(null);
  }
}

void main() {
  testWidgets('Проверка отображения экрана входа', (WidgetTester tester) async {
    // 2. Создаем виджет, обернутый в Провайдеры (как в main.dart)
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Подсовываем наш фейковый сервис вместо настоящего
          Provider<AuthService>(create: (_) => FakeAuthService()),

          // Подсовываем пустой поток пользователя
          StreamProvider<AppUser?>.value(
            value: Stream.value(null),
            initialData: null,
          ),
        ],
        child: const MaterialApp(
          home: Authenticate(),
        ),
      ),
    );

    // Даем время на перерисовку (на всякий случай)
    await tester.pumpAndSettle();

    // 3. Ищем элементы (Убедитесь, что текст совпадает с тем, что у вас на кнопках)
    // Например, если у вас кнопка "Войти" или "Войти в аккаунт"
    // Используем find.byType для надежности, если текст может отличаться
    expect(find.byType(ElevatedButton), findsWidgets); // Должна быть хотя бы одна кнопка
  });
}