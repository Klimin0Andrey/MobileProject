import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKeyPrefix = 'theme_'; // Используем префикс

  bool get isDarkMode => _isDarkMode;

  // Создает уникальный ключ для пользователя
  String _getUserThemeKey(String uid) => '$_themeKeyPrefix$uid';

  Future<void> _saveTheme(String uid, bool isDark) async {
    if (uid.isEmpty) return; // Не сохраняем для пустого uid
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getUserThemeKey(uid), isDark);
  }

  // ✅ ИЗМЕНЕНИЕ 1: Метод теперь требует UID для загрузки темы
  Future<void> loadUserTheme(String uid) async {
    if (uid.isEmpty) return; // Не загружаем для пустого uid
    final prefs = await SharedPreferences.getInstance();
    // Загружаем по уникальному ключу, по умолчанию - светлая тема (false)
    _isDarkMode = prefs.getBool(_getUserThemeKey(uid)) ?? false;
    notifyListeners();
  }

  // ✅ ИЗМЕНЕНИЕ 2: Метод теперь требует UID для сохранения темы
  void toggleTheme(String uid) {
    _isDarkMode = !_isDarkMode;
    _saveTheme(uid, _isDarkMode); // Сохраняем для конкретного пользователя
    notifyListeners();
  }

  // Этот метод для гостя остается без изменений. Он не трогает хранилище.
  void setGuestMode() {
    if (_isDarkMode) {
      _isDarkMode = false;
      notifyListeners();
    }
  }
}