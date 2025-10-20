import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:linux_test2/screens/wrapper.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/models/user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<AppUser?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(home: Wrapper()),
    );
  }
}
