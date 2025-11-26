import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linux_test2/presentation/providers/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    test('Initial state should be light mode (false)', () {
      // Подделываем SharedPreferences (пустые данные)
      SharedPreferences.setMockInitialValues({});

      final themeProvider = ThemeProvider();
      expect(themeProvider.isDarkMode, false);
    });

    // test('toggleTheme should switch mode and save to prefs', () async {
    //   // Подделываем SharedPreferences
    //   SharedPreferences.setMockInitialValues({});
    //
    //   final themeProvider = ThemeProvider();
    //   const uid = 'user_123';
    //
    //   // Меняем тему
    //   themeProvider.toggleTheme(uid);
    //
    //   // Проверяем локальное состояние
    //   expect(themeProvider.isDarkMode, true);
    //
    //   // Проверяем, что сохранилось в "память"
    //   final prefs = await SharedPreferences.getInstance();
    //   expect(prefs.getBool('theme_$uid'), true);
    // });

    test('loadUserTheme should load saved value', () async {
      const uid = 'user_123';
      // Подделываем SharedPreferences: как будто там уже записано true (темная тема)
      SharedPreferences.setMockInitialValues({
        'theme_$uid': true,
      });

      final themeProvider = ThemeProvider();
      await themeProvider.loadUserTheme(uid);

      expect(themeProvider.isDarkMode, true);
    });
  });
}