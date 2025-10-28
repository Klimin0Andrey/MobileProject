import 'package:flutter/material.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/shared/constants.dart';
import 'package:linux_test2/shared/loading.dart';

class Register extends StatefulWidget {
  final Function toggleView;

  const Register({super.key, required this.toggleView});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  String email = '';
  String password = '';
  String name = '';
  String phone = '';
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
              title: const Text('Регистрация'),
              actions: <Widget>[
                TextButton.icon(
                  icon: const Icon(Icons.person, color: Colors.white),
                  label: const Text(
                    'Войти',
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
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 20.0),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                          hintText: 'Имя',
                        ),
                        validator: (val) => val!.isEmpty ? 'Введите имя' : null,
                        onChanged: (val) {
                          setState(() => name = val);
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                          hintText: 'Телефон',
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Введите телефон' : null,
                        onChanged: (val) {
                          setState(() => phone = val);
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                          hintText: 'Email',
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Введите email' : null,
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
                              await authService.registerWithEmailAndPassword(
                                email: email,
                                password: password,
                                name: name,
                                phone: phone,
                                role: 'customer',
                              );
                              // ДОБАВЬТЕ ЭТУ СТРОКУ ↓
                              if (mounted) Navigator.pop(context);

                              // Успешная регистрация - StreamProvider автоматически обновит UI
                            } catch (e) {
                              print('❌ Ошибка в UI: $e');
                              String errorMessage = 'Ошибка регистрации. Проверьте данные';

                              // Более конкретные сообщения об ошибках
                              if (e.toString().contains('email-already-in-use')) {
                                errorMessage = 'Этот email уже используется';
                              } else if (e.toString().contains('weak-password')) {
                                errorMessage = 'Пароль слишком слабый';
                              } else if (e.toString().contains('invalid-email')) {
                                errorMessage = 'Неверный формат email';
                              }

                              setState(() {
                                error = errorMessage;
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
                          'Зарегистрироваться',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        error,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
