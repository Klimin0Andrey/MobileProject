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
  bool _obscurePassword = true; // ✅ ДОБАВЛЕНО: для показа/скрытия пароля

  String email = '';
  String password = '';
  String error = '';

  // ✅ ДОБАВЛЕНО: Валидация email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return loading
        ? const Loading()
        : Scaffold(
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
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20.0),
                TextFormField(
                  decoration: textInputDecoration.copyWith(hintText: 'Email'),
                  validator: _validateEmail, // ✅ ИСПРАВЛЕНО: улучшенная валидация
                  keyboardType: TextInputType.emailAddress, // ✅ ДОБАВЛЕНО
                  onChanged: (val) => setState(() => email = val),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  decoration: textInputDecoration.copyWith(
                    hintText: 'Пароль',
                    suffixIcon: IconButton( // ✅ ДОБАВЛЕНО: кнопка показа/скрытия пароля
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (val) => val!.length < 6
                      ? 'Пароль должен быть 6+ символов'
                      : null,
                  obscureText: _obscurePassword, // ✅ ИСПРАВЛЕНО: используем переменную
                  onChanged: (val) => setState(() => password = val),
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
                        await authService.signInWithEmailAndPassword(email, password);
                        // ✅ ИСПРАВЛЕНО: закрываем экран после успешного входа
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            error = 'Неверный email или пароль';
                            loading = false;
                          });
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Войти', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12.0),
                Text(error, style: const TextStyle(color: Colors.red, fontSize: 14.0)),

                // --- НОВЫЙ БЛОК СОЦСЕТЕЙ ---
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Или войти через", style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Кнопка Google
                OutlinedButton.icon(
                  onPressed: () async {
                    setState(() {
                      loading = true;
                      error = '';
                    });
                    try {
                      final result = await authService.signInWithGoogle();
                      // ✅ ИСПРАВЛЕНО: проверяем успешность и закрываем экран
                      if (result != null && result.user != null && mounted) {
                        Navigator.pop(context);
                      } else if (mounted) {
                        setState(() {
                          loading = false;
                          error = "Ошибка входа через Google";
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          loading = false;
                          error = "Ошибка входа через Google: ${e.toString()}";
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                  label: const Text("Google", style: TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Кнопка GitHub
                OutlinedButton.icon(
                  onPressed: () async {
                    setState(() {
                      loading = true;
                      error = '';
                    });
                    try {
                      final result = await authService.signInWithGitHub();
                      // ✅ ИСПРАВЛЕНО: проверяем успешность и закрываем экран
                      if (result != null && result.user != null && mounted) {
                        Navigator.pop(context);
                      } else if (mounted) {
                        setState(() {
                          loading = false;
                          error = "Ошибка входа через GitHub";
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          loading = false;
                          error = "Ошибка входа через GitHub: ${e.toString()}";
                        });
                      }
                    }
                  },
                  // ✅ ИСПРАВЛЕНО: лучшая иконка для GitHub
                  icon: const Icon(Icons.account_circle, size: 24, color: Colors.black),
                  label: const Text("GitHub", style: TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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