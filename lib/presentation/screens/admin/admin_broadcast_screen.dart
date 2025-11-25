import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  int _sentCount = 0;
  int _totalUsers = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _sentCount = 0;
    });

    try {
      final notificationService = NotificationService();
      final firestore = FirebaseFirestore.instance;

      // Получаем всех пользователей с FCM токенами
      final usersSnapshot = await firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      _totalUsers = usersSnapshot.docs.length;

      if (_totalUsers == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нет пользователей с токенами для отправки'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Отправляем уведомления через Firebase Topics (рекомендуемый способ)
      // Все пользователи должны быть подписаны на тему 'all_users'
      await notificationService.subscribeToTopic('all_users');

      // Для реальной отправки через FCM нужен сервер или Cloud Functions
      // Здесь мы сохраняем уведомление в Firestore для каждого пользователя
      WriteBatch batch = firestore.batch();
      int count = 0;

      for (var doc in usersSnapshot.docs) {
        final userId = doc.id;
        final userRef = firestore.collection('users').doc(userId);

        // Сохраняем уведомление в подколлекцию пользователя
        final notificationRef = userRef.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'broadcast',
        });

        count++;
        if (count % 10 == 0) {
          await batch.commit();
          batch = firestore.batch();
          if (mounted) {
            setState(() => _sentCount = count);
          }
        }
      }

      // Коммитим оставшиеся
      if (count % 10 != 0) {
        await batch.commit();
      }

      if (mounted) {
        setState(() {
          _isSending = false;
          _sentCount = _totalUsers;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Уведомление отправлено $count пользователям'),
            backgroundColor: Colors.green,
          ),
        );

        // Очищаем форму
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Массовая рассылка'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информационная карточка
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Уведомление будет отправлено всем пользователям приложения',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Заголовок
              Text(
                'Заголовок',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Введите заголовок уведомления',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите заголовок';
                  }
                  if (value.trim().length > 100) {
                    return 'Заголовок слишком длинный (макс. 100 символов)';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 24),

              // Текст сообщения
              Text(
                'Текст сообщения',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  hintText: 'Введите текст уведомления',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.message),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите текст сообщения';
                  }
                  if (value.trim().length > 500) {
                    return 'Текст слишком длинный (макс. 500 символов)';
                  }
                  return null;
                },
                maxLength: 500,
              ),
              const SizedBox(height: 32),

              // Прогресс отправки
              if (_isSending) ...[
                LinearProgressIndicator(
                  value: _totalUsers > 0 ? _sentCount / _totalUsers : 0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 8),
                Text(
                  'Отправлено: $_sentCount / $_totalUsers',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
              ],

              // Кнопка отправки
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendBroadcast,
                  icon: _isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'Отправка...' : 'Отправить всем'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}