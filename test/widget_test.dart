import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/data/models/user.dart';

// Тот же фейк
class FakeAuthService extends Fake implements AuthService {
  @override
  Stream<AppUser?> get user => Stream.value(null);
}

void main() {
  testWidgets('Authenticate screen loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => FakeAuthService()),
          StreamProvider<AppUser?>.value(value: Stream.value(null), initialData: null),
        ],
        child: const MaterialApp(
          home: Authenticate(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Проверяем, что экран загрузился (нашел кнопку)
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}