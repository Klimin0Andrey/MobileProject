import 'package:firebase_auth/firebase_auth.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/address.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AppUser?> get user {
    return _auth.authStateChanges().asyncMap(_userFromFirebase);
  }

  // Преобразование User -> AppUser с данными из Firestore
  Future<AppUser?> _userFromFirebase(User? user) async {
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;

        // ✅ ИСПРАВЛЕНО: Обработка адресов с обратной совместимостью
        List<DeliveryAddress> addressesList = [];
        final addressesData = data['addresses'];
        if (addressesData is List) {
          if (addressesData.isNotEmpty) {
            final firstItem = addressesData.first;
            if (firstItem is String) {
              // Старый формат: List<String> - преобразуем в DeliveryAddress
              addressesList = addressesData.map((addressString) {
                return DeliveryAddress(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Адрес',
                  address: addressString,
                  isDefault: addressesList.isEmpty,
                  createdAt: DateTime.now(),
                );
              }).toList();
            } else if (firstItem is Map) {
              // Новый формат: List<Map> - преобразуем в DeliveryAddress
              addressesList = addressesData.map((addressMap) {
                return DeliveryAddress.fromMap(Map<String, dynamic>.from(addressMap));
              }).toList();
            }
          }
        }

        return AppUser(
          uid: user.uid,
          email: data['email'] ?? user.email ?? '',
          role: data['role'] ?? 'customer',
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          addresses: addressesList, // ✅ Теперь правильный тип
          favorites: List<String>.from(data['favorites'] ?? []),
          avatarUrl: data['avatarUrl'],
        );
      } else {
        // Если документа нет, создаем базового пользователя
        return AppUser(
          uid: user.uid,
          email: user.email ?? '',
          role: 'customer',
          name: '',
          phone: '',
          addresses: [], // ✅ Пустой список DeliveryAddress
          favorites: [],
          avatarUrl: null,
        );
      }
    } catch (e) {
      print('Error in _userFromFirebase: $e');
      return null;
    }
  }

  // Анонимный вход (если нужен)
  Future<void> signInAnon() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      print('Anonymous sign in error: $e');
      rethrow;
    }
  }

  // Вход - теперь возвращает Future<void> и пробрасывает ошибки
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Не возвращаем ничего - стрим сам обновится
    } catch (e) {
      print('Sign in error: $e');
      rethrow; // Пробрасываем ошибку для обработки в UI
    }
  }

  // Регистрация
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      print('🚀 Начало регистрации: $email');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      print('✅ Пользователь создан в Firebase Auth: ${user?.uid}');
      if (user != null) {
        // Создаем документ в Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'role': role,
          'addresses': [],
          'favorites': [],
          'avatarUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Профиль создан в Firestore');
      }
      print('🎉 Регистрация завершена успешно');
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Выход
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
}
