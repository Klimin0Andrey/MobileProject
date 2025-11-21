import 'package:flutter/material.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/shared/constants.dart';
import 'package:linux_test2/shared/loading.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class Register extends StatefulWidget {
  final Function toggleView;

  const Register({super.key, required this.toggleView});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _phoneMaskFormatter = MaskTextInputFormatter(
      mask: '+7 (###) ###-##-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  bool _obscurePassword = true; // ✅ ДОБАВЛЕНО: для показа/скрытия пароля
  bool _obscureConfirmPassword = true; // ✅ ДОБАВЛЕНО: для подтверждения пароля

  String email = '';
  String password = '';
  String confirmPassword = ''; // ✅ ДОБАВЛЕНО: поле подтверждения пароля
  String name = '';
  String phone = '';
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
          horizontal: 30.0,
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
                  onChanged: (val) => setState(() => name = val),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  inputFormatters: [_phoneMaskFormatter],
                  keyboardType: TextInputType.phone,
                  decoration: textInputDecoration.copyWith(
                    hintText: 'Телефон',
                  ),
                  validator: (val) =>
                  val!.isEmpty ? 'Введите телефон' : null,
                  onChanged: (val) => setState(() => phone = val),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  decoration: textInputDecoration.copyWith(
                    hintText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress, // ✅ ДОБАВЛЕНО
                  validator: _validateEmail, // ✅ ИСПРАВЛЕНО: улучшенная валидация
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
                // ✅ ДОБАВЛЕНО: Поле подтверждения пароля
                TextFormField(
                  decoration: textInputDecoration.copyWith(
                    hintText: 'Подтвердите пароль',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Подтвердите пароль';
                    }
                    if (val != password) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                  obscureText: _obscureConfirmPassword,
                  onChanged: (val) => setState(() => confirmPassword = val),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => loading = true);
                      try {
                        await authService.registerWithEmailAndPassword(
                          email: email,
                          password: password,
                          name: name,
                          phone: phone,
                          role: 'customer',
                        );
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        String errorMessage = 'Ошибка регистрации';
                        if (e.toString().contains('email-already-in-use')) {
                          errorMessage = 'Этот email уже используется';
                        } else if (e.toString().contains('weak-password')) {
                          errorMessage = 'Пароль слишком слабый';
                        }
                        if (mounted) {
                          setState(() {
                            error = errorMessage;
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

                // --- БЛОК СОЦСЕТЕЙ ---
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Или через соцсети",
                          style: TextStyle(color: Colors.grey)),
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
                          error = "Ошибка регистрации через Google";
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          loading = false;
                          error = "Ошибка регистрации через Google: ${e.toString()}";
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata,
                      size: 32, color: Colors.red),
                  label: const Text("Google",
                      style: TextStyle(color: Colors.black)),
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
                          error = "Ошибка регистрации через GitHub";
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          loading = false;
                          error = "Ошибка регистрации через GitHub: ${e.toString()}";
                        });
                      }
                    }
                  },
                  // ✅ ИСПРАВЛЕНО: лучшая иконка для GitHub
                  icon: const Icon(Icons.account_circle,
                      size: 24, color: Colors.black),
                  label: const Text("GitHub",
                      style: TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}