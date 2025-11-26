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
  final _formKey = GlobalKey<FormState>();

  // Сервисы
  final _adminUsersService = AdminUsersService();

  // Состояние
  bool _isSending = false;
  int _sentCount = 0;
  int _totalUsers = 0;
  bool _sendToAll = true; // Режим отправки: true = всем, false = одному
  AppUser? _selectedUser; // Выбранный пользователь
  String _searchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // --- ЛОГИКА ОТПРАВКИ ---

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    // Проверка выбора пользователя
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
        // 1. Режим отправки ВСЕМ
        // Берем всех пользователей (даже без токена, чтобы сохранить историю в БД)
        final usersSnapshot = await firestore.collection('users').get();

        userIds = usersSnapshot.docs.map((doc) => doc.id).toList();
        _totalUsers = userIds.length;

        if (_totalUsers == 0) {
          if (mounted) {
            setState(() => _isSending = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Нет пользователей в базе данных'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Подписываем админа (себя) или отправляем пуш в топик
        await notificationService.subscribeToTopic('all_users');
      } else {
        // 2. Режим отправки КОНКРЕТНОМУ
        if (_selectedUser == null) return;
        userIds = [_selectedUser!.uid];
        _totalUsers = 1;
      }

      // Сохраняем уведомления в Firestore (Batch Write)
      // Firestore лимит: 500 операций за раз. Будем писать пачками.
      WriteBatch batch = firestore.batch();
      int count = 0;
      int batchCount = 0; // Счетчик внутри текущего батча

      for (var userId in userIds) {
        final userRef = firestore.collection('users').doc(userId);
        final notificationRef = userRef.collection('notifications').doc();

        batch.set(notificationRef, {
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'type': _sendToAll ? 'broadcast' : 'personal',
        });

        count++;
        batchCount++;

        // Если набралось 400 операций, отправляем и очищаем батч
        if (batchCount >= 400) {
          await batch.commit();
          batch = firestore.batch(); // ✅ ИСПРАВЛЕНО: Создаем новый батч
          batchCount = 0;

          if (mounted) {
            setState(() => _sentCount = count);
          }
        }
      }

      // Коммитим остаток
      if (batchCount > 0) {
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

        // Очистка
        _titleController.clear();
        _bodyController.clear();
        if (!_sendToAll) {
          setState(() {
            _selectedUser = null;
            _searchQuery = '';
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

  // Метод вызова диалога
  Future<void> _selectUser() async {
    final selected = await showDialog<AppUser>(
      context: context,
      builder: (context) => _UserSelectionDialog(
        searchQuery: _searchQuery,
        onSearchChanged: (query) {
          // Обновляем query локально в виджете, если нужно сохранить состояние
          _searchQuery = query;
        },
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedUser = selected;
        _searchQuery = '';
      });
    }
  }

  // --- ИНТЕРФЕЙС (UI) ---

  @override
  Widget build(BuildContext context) {
    // Определение темы
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Цветовая палитра
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[850] : Colors.orange.shade50;
    final inputFillColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey.shade300;

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
              // 1. Карточка выбора режима
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Кому отправить?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          RadioListTile<bool>(
                            title: Text(
                              'Всем пользователям',
                              style: TextStyle(color: textColor),
                            ),
                            value: true,
                            groupValue: _sendToAll,
                            activeColor: Colors.orange,
                            onChanged: _isSending
                                ? null
                                : (value) {
                              setState(() {
                                _sendToAll = value ?? true;
                                _selectedUser = null;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<bool>(
                            title: Text(
                              'Конкретному пользователю',
                              style: TextStyle(color: textColor),
                            ),
                            value: false,
                            groupValue: _sendToAll,
                            activeColor: Colors.orange,
                            onChanged: _isSending
                                ? null
                                : (value) {
                              setState(() {
                                _sendToAll = value ?? false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Блок выбора пользователя (только если не "Всем")
              if (!_sendToAll) ...[
                Text(
                  'Выберите пользователя',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isSending ? null : _selectUser,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                      color: inputFillColor,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: _selectedUser != null
                              ? Colors.orange
                              : subTextColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _selectedUser != null
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedUser!.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedUser!.email,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 14,
                                ),
                              ),
                              if (_selectedUser!.phone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _selectedUser!.phone,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          )
                              : Text(
                            'Нажмите для выбора пользователя',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_selectedUser != null)
                          IconButton(
                            icon: Icon(Icons.close, color: subTextColor),
                            onPressed: _isSending
                                ? null
                                : () {
                              setState(() {
                                _selectedUser = null;
                              });
                            },
                            tooltip: 'Очистить выбор',
                          ),
                        Icon(Icons.arrow_forward_ios,
                            size: 16, color: subTextColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 3. Инфо карточка
              Card(
                color: isDark
                    ? Colors.blue.shade900.withOpacity(0.4)
                    : Colors.blue.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark
                            ? Colors.blue.shade200
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _sendToAll
                              ? 'Уведомление будет отправлено всем пользователям приложения'
                              : 'Уведомление будет отправлено только выбранному пользователю',
                          style: TextStyle(
                            color: isDark
                                ? Colors.blue.shade100
                                : Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Поле Заголовка
              Text(
                'Заголовок',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Введите заголовок уведомления',
                  hintStyle: TextStyle(color: subTextColor),
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  prefixIcon: const Icon(Icons.title, color: Colors.orange),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите заголовок';
                  }
                  if (value.trim().length > 100) {
                    return 'Макс. 100 символов';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 24),

              // 5. Поле Текста
              Text(
                'Текст сообщения',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Введите текст уведомления',
                  hintStyle: TextStyle(color: subTextColor),
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  prefixIcon: const Icon(Icons.message, color: Colors.orange),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите текст сообщения';
                  }
                  if (value.trim().length > 500) {
                    return 'Макс. 500 символов';
                  }
                  return null;
                },
                maxLength: 500,
              ),
              const SizedBox(height: 32),

              // 6. Индикатор прогресса
              if (_isSending) ...[
                LinearProgressIndicator(
                  value: _totalUsers > 0 ? _sentCount / _totalUsers : 0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 8),
                Text(
                  'Отправлено: $_sentCount / $_totalUsers',
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
                const SizedBox(height: 24),
              ],

              // 7. Кнопка отправки
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
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
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

// --- ДИАЛОГ ВЫБОРА ПОЛЬЗОВАТЕЛЯ ---

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
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _currentSearchQuery = widget.searchQuery;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _currentSearchQuery = _searchController.text;
    });
    widget.onSearchChanged(_searchController.text);
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin': return 'Админ';
      case 'courier': return 'Курьер';
      case 'customer': return 'Клиент';
      default: return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'courier': return Colors.blue;
      case 'customer': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Цвета для диалога
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final inputFillColor = isDark ? Colors.grey[800] : Colors.white;

    return Dialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      Text(
                        'Выберите пользователя',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Поиск (имя, email, телефон)',
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon: const Icon(Icons.search, color: Colors.orange),
                      filled: true,
                      fillColor: inputFillColor,
                      suffixIcon: _currentSearchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: hintColor),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      // Изменения обрабатываются через listener
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),

            // Список пользователей
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: _adminUsersService.searchUsers(_currentSearchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.orange));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Ошибка: ${snapshot.error}', style: TextStyle(color: textColor)));
                  }

                  final users = snapshot.data ?? [];

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _currentSearchQuery.isEmpty
                                ? 'Нет пользователей'
                                : 'Пользователи не найдены',
                            style: TextStyle(color: hintColor, fontSize: 16),
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
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email, style: TextStyle(color: hintColor)),
                            if (user.phone.isNotEmpty)
                              Text(user.phone, style: TextStyle(color: hintColor, fontSize: 12)),
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
                          side: BorderSide.none,
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