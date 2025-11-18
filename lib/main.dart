// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:linux_test2/presentation/providers/support_provider.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/presentation/screens/role_wrapper.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/providers/restaurant_provider.dart';
import 'package:linux_test2/presentation/providers/order_provider.dart';
import 'package:linux_test2/presentation/providers/theme_provider.dart';
import 'package:linux_test2/presentation/providers/address_provider.dart';
import 'package:linux_test2/core/themes/app_themes.dart';

void main() async {
  // Инициализация Flutter и Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Создаем ЕДИНСТВЕННЫЙ экземпляр AuthService для всего приложения
    final authService = AuthService();

    return MultiProvider(
      providers: [
        // 2. Предоставляем этот экземпляр всем виджетам ниже по дереву
        Provider<AuthService>.value(value: authService),

        // 3. Используем тот же экземпляр для прослушивания изменений состояния аутентификации
        StreamProvider<AppUser?>.value(
          value: authService.user,
          initialData: null,
          catchError: (_, error) {
            debugPrint('Ошибка в потоке пользователя (StreamProvider): $error');
            return null;
          },
        ),

        // Остальные провайдеры вашего приложения
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),

        // Провайдер адресов, который зависит от текущего пользователя (AppUser)
        ChangeNotifierProxyProvider<AppUser?, AddressProvider>(
          create: (_) => AddressProvider(uid: ''),
          update: (_, user, previousProvider) {
            // Если пользователь вышел (user == null), возвращаем провайдер с пустым uid
            if (user == null) {
              return AddressProvider(uid: '');
            }
            // Если пользователь не изменился, используем старый провайдер
            if (previousProvider != null && previousProvider.uid == user.uid) {
              return previousProvider;
            }
            // Если вошел новый пользователь, создаем для него новый провайдер адресов
            return AddressProvider(uid: user.uid);
          },
        ),
      ],
      // Consumer следит за изменениями в ThemeProvider и перестраивает MaterialApp
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'YumYum',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const RoleBasedWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}