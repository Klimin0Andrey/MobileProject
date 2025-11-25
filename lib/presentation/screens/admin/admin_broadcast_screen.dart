import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/notification_service.dart';
import 'package:linux_test2/services/admin_users_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _adminUsersService = AdminUsersService();

  bool _isSending = false;
  int _sentCount = 0;
  int _totalUsers = 0;
  bool _sendToAll = true; // ✅ ДОБАВЛЕНО: Режим отправки
  AppUser? _selectedUser; // ✅ ДОБАВЛЕНО: Выбранный пользователь
  String _searchQuery = ''; // ✅ ДОБАВЛЕНО: Поисковый запрос

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ ДОБАВЛЕНО: Проверка выбора пользователя
    if (!_sendToAll && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите пользователя для отправки'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _sentCount = 0;
    });

    try {
      final notificationService = NotificationService();
      final firestore = FirebaseFirestore.instance;

      List<String> userIds = [];

      if (_sendToAll) {
        // ✅ Режим отправки всем пользователям
        final usersSnapshot = await firestore
            .collection('users')
            .where('fcmToken', isNotEqualTo: null)
            .get();

        userIds = usersSnapshot.docs.map((doc) => doc.id).toList();
        _totalUsers = userIds.length;

        if (_totalUsers == 0) {
          if (mounted) {
            setState(() => _isSending = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Нет пользователей с токенами для отправки'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Подписываем на тему для массовой рассылки
        await notificationService.subscribeToTopic('all_users');
      } else {
        // ✅ Режим отправки конкретному пользователю
        if (_selectedUser == null) return;

        // Проверяем наличие FCM токена у выбранного пользователя
        final userDoc = await firestore.collection('users').doc(_selectedUser!.uid).get();
        final userData = userDoc.data();

        if (userData == null || userData['fcmToken'] == null) {
          if (mounted) {
            setState(() => _isSending = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('У выбранного пользователя нет FCM токена'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        userIds = [_selectedUser!.uid];
        _totalUsers = 1;
      }

      // Сохраняем уведомление в Firestore для каждого пользователя
      WriteBatch batch = firestore.batch();
      int count = 0;

      for (var userId in userIds) {
        final userRef = firestore.collection('users').doc(userId);

        // Сохраняем уведомление в подколлекцию пользователя
        final notificationRef = userRef.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'type': _sendToAll ? 'broadcast' : 'personal',
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
            content: Text(
              _sendToAll
                  ? 'Уведомление отправлено $count пользователям'
                  : 'Уведомление отправлено пользователю ${_selectedUser!.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Очищаем форму
        _titleController.clear();
        _bodyController.clear();
        if (!_sendToAll) {
          setState(() {
            _selectedUser = null;
            _searchQuery = '';
            _searchController.clear();
          });
        }
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

  // ✅ ДОБАВЛЕНО: Метод для выбора пользователя
  Future<void> _selectUser() async {
    final selected = await showDialog<AppUser>(
      context: context,
      builder: (context) => _UserSelectionDialog(
        searchQuery: _searchQuery,
        onSearchChanged: (query) {
          setState(() => _searchQuery = query);
        },
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedUser = selected;
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рассылка уведомлений'),
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
              // ✅ ДОБАВЛЕНО: Переключатель режима отправки
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Кому отправить?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Всем пользователям'),
                              value: true,
                              groupValue: _sendToAll,
                              onChanged: _isSending
                                  ? null
                                  : (value) {
                                setState(() {
                                  _sendToAll = value ?? true;
                                  _selectedUser = null;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Конкретному пользователю'),
                              value: false,
                              groupValue: _sendToAll,
                              onChanged: _isSending
                                  ? null
                                  : (value) {
                                setState(() {
                                  _sendToAll = value ?? false;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ ДОБАВЛЕНО: Выбор пользователя (если режим "конкретному")
              if (!_sendToAll) ...[
                Text(
                  'Выберите пользователя',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isSending ? null : _selectUser,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: _selectedUser != null
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _selectedUser != null
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedUser!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedUser!.email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              if (_selectedUser!.phone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _selectedUser!.phone,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          )
                              : Text(
                            'Нажмите для выбора пользователя',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (_selectedUser != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _isSending
                                ? null
                                : () {
                              setState(() {
                                _selectedUser = null;
                              });
                            },
                            tooltip: 'Очистить выбор',
                          ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

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
                          _sendToAll
                              ? 'Уведомление будет отправлено всем пользователям приложения'
                              : 'Уведомление будет отправлено выбранному пользователю',
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
                  label: Text(
                    _isSending
                        ? 'Отправка...'
                        : (_sendToAll
                        ? 'Отправить всем'
                        : 'Отправить пользователю'),
                  ),
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

// ✅ ДОБАВЛЕНО: Диалог выбора пользователя
class _UserSelectionDialog extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _UserSelectionDialog({
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  State<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  final _searchController = TextEditingController();
  final _adminUsersService = AdminUsersService();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'courier':
        return 'Курьер';
      case 'customer':
        return 'Клиент';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'courier':
        return Colors.blue;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок и поиск
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Выберите пользователя',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск по имени, email или телефону',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                          setState(() {});
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      widget.onSearchChanged(value);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Список пользователей
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: _adminUsersService.searchUsers(_searchController.text),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Ошибка: ${snapshot.error}'),
                    );
                  }

                  final users = snapshot.data ?? [];

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Нет пользователей'
                                : 'Пользователи не найдены',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                          child: Text(
                            user.initials,
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            if (user.phone.isNotEmpty) Text(user.phone),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            _getRoleLabel(user.role),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _getRoleColor(user.role),
                          ),
                        ),
                        onTap: () => Navigator.pop(context, user),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}