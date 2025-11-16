import 'package:linux_test2/data/models/dish.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;

  DatabaseService({required this.uid});

  // Коллекции (как в Brew)
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference restaurantCollection = FirebaseFirestore.instance
      .collection('restaurants');
  final CollectionReference dishCollection = FirebaseFirestore.instance
      .collection('dishes');

  // Добавьте этот метод в класс DatabaseService в database.dart
  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    return await userCollection.doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'addresses': [],
      'favorites': [],
      'avatarUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // === МЕТОДЫ ДЛЯ ПОЛЬЗОВАТЕЛЕЙ (из Brew) ===
  Future<void> updateUserData(String name, String phone, String role) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'phone': phone,
      'role': role,
      'addresses': [],
      'favorites': [],
    });
  }

  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserData(
      uid: uid,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'customer',
      addresses: List<String>.from(data['addresses'] ?? []),
      favorites: List<String>.from(data['favorites'] ?? []),
      avatarUrl: data['avatarUrl'],
    );
  }

  Stream<UserData> get userData {
    return userCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }

  // === НОВЫЕ МЕТОДЫ ДЛЯ РЕСТОРАНОВ ===

  // Получить все рестораны (аналог get brews из Brew)
  Stream<List<Restaurant>> get restaurants {
    return restaurantCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(_restaurantListFromSnapshot);
  }

  // Получить рестораны по категории
  Stream<List<Restaurant>> getRestaurantsByCuisine(String cuisine) {
    return restaurantCollection
        .where('isActive', isEqualTo: true)
        .where('cuisineType', arrayContains: cuisine)
        .snapshots()
        .map(_restaurantListFromSnapshot);
  }

  // Преобразование данных ресторанов (аналог _brewListFromSnapshot)
  List<Restaurant> _restaurantListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return _restaurantFromSnapshot(doc);
    }).toList();
  }

  Restaurant _restaurantFromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      deliveryTime: data['deliveryTime'] ?? '',
      cuisineType: List<String>.from(data['cuisineType'] ?? []),
      isActive: data['isActive'] ?? false,
    );
  }

  // === МЕТОДЫ ДЛЯ БЛЮД ===

  // Получить блюда ресторана
  Stream<List<Dish>> getDishesByRestaurant(String restaurantId) {
    return dishCollection
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(_dishListFromSnapshot);
  }

  List<Dish> _dishListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Dish(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        imageUrl: data['imageUrl'] ?? '',
        category: data['category'] ?? '',
        restaurantId: data['restaurantId'] ?? '',
        isAvailable: data['isAvailable'] ?? false,
      );
    }).toList();
  }

  // Добавьте эти методы в класс DatabaseService:

// Добавить ресторан в избранное
  Future<void> addToFavorites(String restaurantId) async {
    return await userCollection.doc(uid).update({
      'favorites': FieldValue.arrayUnion([restaurantId])
    });
  }

// Удалить ресторан из избранного
  Future<void> removeFromFavorites(String restaurantId) async {
    return await userCollection.doc(uid).update({
      'favorites': FieldValue.arrayRemove([restaurantId])
    });
  }

// Получить избранные рестораны
  Stream<List<Restaurant>> get favoriteRestaurants {
    return userCollection.doc(uid).snapshots().asyncMap((userSnapshot) async {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final favoriteIds = List<String>.from(userData?['favorites'] ?? []);

      if (favoriteIds.isEmpty) return [];

      // Получаем рестораны по ID из избранного
      final restaurantsSnapshot = await restaurantCollection
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .where('isActive', isEqualTo: true)
          .get();

      return restaurantsSnapshot.docs
          .map((doc) => _restaurantFromSnapshot(doc))
          .toList();
    });
  }

// Проверить, находится ли ресторан в избранном
  Stream<bool> isRestaurantFavorite(String restaurantId) {
    return userCollection.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      final favorites = List<String>.from(data?['favorites'] ?? []);
      return favorites.contains(restaurantId);
    });
  }

}
