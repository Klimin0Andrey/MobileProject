import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/admin_users_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/presentation/widgets/universal_image.dart';
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<AdminUsersProvider>(context, listen: false)
        .setSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Клиенты'),
            Tab(icon: Icon(Icons.people), text: 'Сотрудники'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по имени, email или телефону...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Список пользователей
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList(true), // Клиенты
                _buildUsersList(false), // Сотрудники
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(bool isCustomers) {
    return StreamBuilder<List<AppUser>>(
      stream: isCustomers
          ? Provider.of<AdminUsersProvider>(context).getCustomers()
          : Provider.of<AdminUsersProvider>(context).getEmployees(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCustomers ? Icons.person_outline : Icons.people_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  isCustomers ? 'Нет клиентов' : 'Нет сотрудников',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index], isCustomers);
          },
        );
      },
    );
  }

  Widget _buildUserCard(AppUser user, bool isCustomers) {
    // Проверяем, забанен ли пользователь
    // Примечание: нужно добавить поле isBanned в Firestore
    // Пока используем проверку через FutureBuilder
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        // ✅ ИСПРАВЛЕНО: Правильное приведение типов
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final isBanned = data?['isBanned'] as bool? ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: isBanned ? Colors.red.shade50 : null,
          child: ListTile(
            leading: CircleAvatar(
              radius: 20, // Стандартный размер
              backgroundColor: Colors.grey.shade200, // Цвет фона под картинкой
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? ClipOval(
                child: UniversalImage(
                  imageUrl: user.avatarUrl!,
                  width: 40, // 2 * radius
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: Center(child: Text(user.initials)), // Если картинка битая — инициалы
                ),
              )
                  : Text(user.initials), // Если ссылки нет — инициалы
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isBanned ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (isBanned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Забанен',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📧 ${user.email}'),
                if (user.phone.isNotEmpty) Text('📱 ${user.phone}'),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        _getRoleText(user.role),
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (isCustomers) ...[
                      const SizedBox(width: 8),
                      FutureBuilder<int>(
                        future: Provider.of<AdminUsersProvider>(context, listen: false)
                            .getUserOrdersCount(user.uid),
                        builder: (context, snapshot) {
                          final ordersCount = snapshot.data ?? 0;
                          return Text(
                            '📦 $ordersCount заказов',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                if (!isCustomers)
                  PopupMenuItem(
                    value: 'role',
                    child: const Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Изменить роль'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: isBanned ? 'unban' : 'ban',
                  child: Row(
                    children: [
                      Icon(
                        isBanned ? Icons.check_circle : Icons.block,
                        size: 20,
                        color: isBanned ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBanned ? 'Разбанить' : 'Забанить',
                        style: TextStyle(
                          color: isBanned ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'ban') {
                  _banUser(user);
                } else if (value == 'unban') {
                  _unbanUser(user);
                } else if (value == 'role') {
                  _showChangeRoleDialog(user);
                }
              },
            ),
          ),
        );
      },
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Админ';
      case 'courier':
        return 'Курьер';
      case 'customer':
      default:
        return 'Клиент';
    }
  }

  Future<void> _banUser(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Забанить пользователя?'),
        content: Text('Вы уверены, что хотите забанить "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Забанить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<AdminUsersProvider>(context, listen: false)
            .banUser(user.uid, true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Пользователь ${user.name} забанен')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  Future<void> _unbanUser(AppUser user) async {
    try {
      await Provider.of<AdminUsersProvider>(context, listen: false)
          .banUser(user.uid, false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пользователь ${user.name} разбанен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _showChangeRoleDialog(AppUser user) async {
    String? selectedRole = user.role;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить роль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Клиент'),
              value: 'customer',
              groupValue: selectedRole,
              onChanged: (value) {
                selectedRole = value;
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              title: const Text('Курьер'),
              value: 'courier',
              groupValue: selectedRole,
              onChanged: (value) {
                selectedRole = value;
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              title: const Text('Админ'),
              value: 'admin',
              groupValue: selectedRole,
              onChanged: (value) {
                selectedRole = value;
                Navigator.pop(context, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (result != null && result != user.role) {
      try {
        await Provider.of<AdminUsersProvider>(context, listen: false)
            .updateUserRole(user.uid, result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Роль изменена на ${_getRoleText(result)}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }
}
