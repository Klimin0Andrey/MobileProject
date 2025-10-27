import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/presentation/screens/role_wrapper.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/providers/restaurant_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(  // ← Замени StreamProvider на MultiProvider
      providers: [
        StreamProvider<AppUser?>.value(
          value: AuthService().user,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (context) => CartProvider()), // ← Добавь CartProvider
        ChangeNotifierProvider(create: (context) => RestaurantProvider()),
      ],
      child: MaterialApp(
        title: 'Food Delivery',
        theme: ThemeData(fontFamily: 'Poppins'),
        home: const RoleBasedWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


