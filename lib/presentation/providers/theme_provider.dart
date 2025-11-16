import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _isGuestMode = false;
  static const String _themeKey = 'isDarkMode';
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isGuestMode => _isGuestMode;

  ThemeProvider() {
    _loadTheme();
  }

  // Загрузка темы из SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  // Сохранение темы в SharedPreferences
  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  void toggleTheme() {
    if (_isGuestMode) return;

    _isDarkMode = !_isDarkMode;
    _saveTheme(_isDarkMode);
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveTheme(_isDarkMode);
    notifyListeners();
  }

  // Методы для управления гостевым режимом
  void enableGuestMode() {
    _isGuestMode = true;
    _isDarkMode = false; // ← Принудительно светлая тема для гостей
    notifyListeners();
  }

  void disableGuestMode() {
    _isGuestMode = false;
    _loadTheme(); // ← Загружаем сохраненную тему пользователя
    notifyListeners();
  }
}