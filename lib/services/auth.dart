import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:rxdart/rxdart.dart';
import 'package:linux_test2/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ✅ ИСПРАВЛЕНО: для версии 6.x используется простой конструктор
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Stream<AppUser?> get user {
    return _auth.authStateChanges().switchMap((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      } else {
        return _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots()
            .map(_userFromFirestore);
      }
    });
  }

  // Вспомогательный метод преобразования
  AppUser _userFromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    List<DeliveryAddress> addressesList = [];
    final addressesData = data['addresses'];
    if (addressesData is List) {
      if (addressesData.isNotEmpty) {
        final firstItem = addressesData.first;
        if (firstItem is String) {
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

  // Вход через Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Выбор аккаунта (старый API работает с signIn())
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Отмена

      // 2. Получение токенов
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Создание креденшела
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Вход в Firebase
      final UserCredential result = await _auth.signInWithCredential(credential);

      // 5. Создаем документ юзера в БД, если его нет
      await _createFirestoreUserIfNew(result.user);
      // ✅ СОХРАНЯЕМ ТОКЕН ПРИ ВХОДЕ
      await NotificationService().saveTokenToDatabase();

      return result;
    } catch (e) {
      print("Google Sign In Error: $e");
      rethrow;
    }
  }

  // Вход через GitHub
  Future<UserCredential?> signInWithGitHub() async {
    try {
      // ⚠️ ВНИМАНИЕ: GitHub OAuth через Firebase Auth работает только на Web
      // Для мобильных устройств нужна другая реализация
      // Пока используем OAuthProvider, но это может не работать на мобильных
      final OAuthProvider githubProvider = OAuthProvider('github.com');

      // Для веб используем signInWithPopup, для мобильных это может не работать
      // Если нужно на мобильных, используйте url_launcher для открытия браузера
      final UserCredential result = await _auth.signInWithProvider(githubProvider);

      // Создаем документ юзера в БД, если его нет
      await _createFirestoreUserIfNew(result.user);
      // ✅ СОХРАНЯЕМ ТОКЕН ПРИ ВХОДЕ
      await NotificationService().saveTokenToDatabase();

      return result;
    } catch (e) {
      print("GitHub Sign In Error: $e");
      // Если GitHub не работает на мобильных, можно вернуть null
      // или показать сообщение пользователю
      rethrow;
    }
  }

  // ✅ Вспомогательный метод: Создание юзера в БД при входе через соцсети
  Future<void> _createFirestoreUserIfNew(User? user) async {
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? 'User',
        'phone': '', // Соцсети редко отдают телефон
        'role': 'customer', // По умолчанию клиент
        'addresses': [],
        'favorites': [],
        'avatarUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }


  Future<void> signInAnon() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      print('Anonymous sign in error: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // ✅ СОХРАНЯЕМ ТОКЕН ПРИ ВХОДЕ
      await NotificationService().saveTokenToDatabase();
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

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
        // ✅ СОХРАНЯЕМ ТОКЕН ПРИ РЕГИСТРАЦИИ
        await NotificationService().saveTokenToDatabase();
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending reset email: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Важно выйти из Google тоже
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
}