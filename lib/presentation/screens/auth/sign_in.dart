import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/shared/constants.dart';
import 'package:linux_test2/shared/loading.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;

  const SignIn({super.key, required this.toggleView});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0.0,
        title: const Text('Вход в систему'),
        actions: <Widget>[
          TextButton.icon(
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Регистрация',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              widget.toggleView();
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 50.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: textInputDecoration.copyWith(
                  hintText: 'Email',
                ),
                validator: (val) => val!.isEmpty ? 'Введите email' : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: textInputDecoration.copyWith(
                  hintText: 'Пароль',
                ),
                validator: (val) => val!.length < 6
                    ? 'Пароль должен быть 6+ символов'
                    : null,
                obscureText: true,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      loading = true;
                      error = '';
                    });

                    try {
                      final authService = AuthService();//Provider.of<AuthService>(context, listen: false);
                      await authService.signInWithEmailAndPassword(email, password);
                      // Успешный вход - StreamProvider автоматически обновит UI
                      // НЕ вызываем Navigator.pop() здесь!
                      if (mounted) Navigator.pop(context);

                    } catch (e) {
                      setState(() {
                        error = 'Неверный email или пароль';
                        loading = false;
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Войти',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
