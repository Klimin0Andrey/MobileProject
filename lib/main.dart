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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),

        StreamProvider<AppUser?>.value(
          value: AuthService().user,
          initialData: null,
          catchError: (_, error) {
            debugPrint('Error in user stream: $error');
            return null;
          },
        ),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),

        // ✅ ДОБАВЛЯЕМ AddressProvider с зависимостью от пользователя
        ChangeNotifierProxyProvider<AppUser?, AddressProvider>(
          create: (context) => AddressProvider(uid: ''),
          update: (context, user, previousProvider) {
            // Если пользователь изменился, создаем новый провайдер
            if (user == null) {
              return AddressProvider(uid: '');
            }

            // Если провайдер уже существует и пользователь тот же, возвращаем его
            if (previousProvider != null && previousProvider.uid == user.uid) {
              return previousProvider;
            }

            // Создаем новый провайдер для нового пользователя
            return AddressProvider(uid: user.uid);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        // ← оборачиваем в Consumer
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'YumYum',
            theme: AppThemes.lightTheme,
            // ← используем светлую тему
            darkTheme: AppThemes.darkTheme,
            // ← используем тёмную тему
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            // ← управляем темой
            home: const RoleBasedWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
