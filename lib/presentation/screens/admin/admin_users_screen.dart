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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Поиск по имени, email...',
                hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
                  isCustomers ? Icons.person_off_outlined : Icons.people_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  isCustomers ? 'Нет клиентов' : 'Нет сотрудников',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index], isCustomers);
          },
        );
      },
    );
  }

  Widget _buildUserCard(AppUser user, bool isCustomers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final isBanned = data?['isBanned'] as bool? ?? false;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          color: isBanned
              ? (isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50)
              : Theme.of(context).cardColor,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.orange.shade100,
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? ClipOval(
                child: UniversalImage(
                  imageUrl: user.avatarUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: Center(
                      child: Text(user.initials,
                          style: TextStyle(color: Colors.orange.shade800))),
                ),
              )
                  : Text(user.initials,
                  style: TextStyle(
                      color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.name.isNotEmpty ? user.name : 'Без имени',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                      decoration: isBanned ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (isBanned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BAN',
                      style: TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(color: subTextColor, fontSize: 13)),
                if (user.phone.isNotEmpty)
                  Text(user.phone, style: TextStyle(color: subTextColor, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: _getRoleColor(user.role).withOpacity(0.5)),
                      ),
                      child: Text(
                        _getRoleText(user.role),
                        style: TextStyle(
                            fontSize: 11,
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isCustomers) ...[
                      const SizedBox(width: 12),
                      FutureBuilder<int>(
                        future: Provider.of<AdminUsersProvider>(context, listen: false)
                            .getUserOrdersCount(user.uid),
                        builder: (context, snapshot) {
                          final ordersCount = snapshot.data ?? 0;
                          return Text(
                            '$ordersCount заказов',
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: subTextColor),
              itemBuilder: (context) => [
                // ✅ ДОБАВЛЕНО: Пункт меню "Изменить роль"
                PopupMenuItem(
                  value: 'changeRole',
                  child: Row(
                    children: const [
                      Icon(
                        Icons.manage_accounts,
                        size: 20,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 12),
                      Text('Изменить роль'),
                    ],
                  ),
                ),
                // Пункт меню "Бан/Разбан"
                PopupMenuItem(
                  value: isBanned ? 'unban' : 'ban',
                  child: Row(
                    children: [
                      Icon(
                        isBanned ? Icons.check_circle_outline : Icons.block,
                        size: 20,
                        color: isBanned ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
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
                if (value == 'changeRole') {
                  _showChangeRoleDialog(user); // ✅ Вызов метода смены роли
                } else if (value == 'ban') {
                  _banUser(user);
                } else if (value == 'unban') {
                  _unbanUser(user);
                }
              },
            ),
          ),
        );
      },
    );
  }

  // Метод для получения цвета роли
  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'courier':
        return Colors.blue;
      default:
        return Colors.green;
    }
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
        title: const Text('Блокировка'),
        content: Text('Забанить пользователя "${user.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            const SnackBar(content: Text('Пользователь забанен')),
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
          const SnackBar(content: Text('Пользователь разбанен')),
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

  // Метод смены роли
  Future<void> _showChangeRoleDialog(AppUser user) async {
    String? selectedRole = user.role;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder( // ✅ StatefulBuilder для обновления радиокнопок
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Изменить роль'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Клиент'),
                    value: 'customer',
                    groupValue: selectedRole,
                    onChanged: (v) {
                      setState(() => selectedRole = v);
                      Navigator.pop(context, v);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Курьер'),
                    value: 'courier',
                    groupValue: selectedRole,
                    onChanged: (v) {
                      setState(() => selectedRole = v);
                      Navigator.pop(context, v);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Админ'),
                    value: 'admin',
                    groupValue: selectedRole,
                    onChanged: (v) {
                      setState(() => selectedRole = v);
                      Navigator.pop(context, v);
                    },
                  ),
                ],
              ),
            );
          }
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