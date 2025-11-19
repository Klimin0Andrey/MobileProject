// lib/services/auth.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:rxdart/rxdart.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ ИЗМЕНЕННЫЙ СТРИМ ДЛЯ РЕАКТИВНОСТИ
  Stream<AppUser?> get user {
    return _auth.authStateChanges().switchMap((firebaseUser) {
      if (firebaseUser == null) {
        // Если пользователь вышел, возвращаем стрим с одним null
        return Stream.value(null);
      } else {
        // Если пользователь вошел, подписываемся на его документ в Firestore.
        // Любые изменения в документе (например, обновление avatarUrl)
        // приведут к новому событию в этом стриме.
        return _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots() // snapshots() возвращает Stream<DocumentSnapshot>
            .map(_userFromFirestore); // Преобразуем каждый снимок в AppUser
      }
    });
  }

  // ✅ НОВЫЙ ВСПОМОГАТЕЛЬНЫЙ МЕТОД
  // Преобразует DocumentSnapshot из Firestore в наш объект AppUser.
  AppUser _userFromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    List<DeliveryAddress> addressesList = [];
    final addressesData = data['addresses'];
    if (addressesData is List) {
      if (addressesData.isNotEmpty) {
        final firstItem = addressesData.first;
        if (firstItem is String) { // Обратная совместимость
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
          addressesList = addressesData
              .map((addressMap) =>
              DeliveryAddress.fromMap(Map<String, dynamic>.from(addressMap)))
              .toList();
        }
      }
    }

    return AppUser(
      uid: snapshot.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      addresses: addressesList,
      favorites: List<String>.from(data['favorites'] ?? []),
      avatarUrl: data['avatarUrl'],
    );
  }


  // --- ОСТАЛЬНЫЕ МЕТОДЫ ОСТАЮТСЯ БЕЗ ИЗМЕНЕНИЙ ---

  // Анонимный вход
  Future<void> signInAnon() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      print('Anonymous sign in error: $e');
      rethrow;
    }
  }

  // Вход по email и паролю
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
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
      }
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