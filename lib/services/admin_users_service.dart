import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/user.dart';

class AdminUsersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получить всех пользователей
  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'uid': doc.id,
                }))
            .toList());
  }

  // Получить клиентов
  Stream<List<AppUser>> getCustomers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'uid': doc.id,
                }))
            .toList());
  }

  // Получить сотрудников (админы и курьеры)
  Stream<List<AppUser>> getEmployees() {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['admin', 'courier'])
        .orderBy('role')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'uid': doc.id,
                }))
            .toList());
  }

  // Забанить/разбанить пользователя
  Future<void> banUser(String uid, bool isBanned) async {
    await _firestore.collection('users').doc(uid).update({
      'isBanned': isBanned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Изменить роль пользователя
  Future<void> updateUserRole(String uid, String role) async {
    if (!['customer', 'courier', 'admin'].contains(role)) {
      throw Exception('Некорректная роль');
    }

    await _firestore.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Обновить данные пользователя
  Future<void> updateUser({
    required String uid,
    String? name,
    String? phone,
    String? email,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (phone != null) updateData['phone'] = phone;
    if (email != null) updateData['email'] = email;

    await _firestore.collection('users').doc(uid).update(updateData);
  }

  // Получить статистику пользователя (количество заказов)
  Future<int> getUserOrdersCount(String userId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  // Поиск пользователей
  Stream<List<AppUser>> searchUsers(String query) {
    if (query.isEmpty) {
      return getAllUsers();
    }

    // Firestore не поддерживает полнотекстовый поиск
    // Поэтому получаем всех и фильтруем в памяти
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      final allUsers = snapshot.docs
          .map((doc) => AppUser.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'uid': doc.id,
              }))
          .toList();

      final lowerQuery = query.toLowerCase();
      return allUsers.where((user) {
        return user.name.toLowerCase().contains(lowerQuery) ||
            user.email.toLowerCase().contains(lowerQuery) ||
            user.phone.contains(query);
      }).toList();
    });
  }
}






