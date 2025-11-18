// lib/services/database.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/data/models/dish.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/data/models/user.dart';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid});

  // --- Коллекции ---
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference restaurantCollection = FirebaseFirestore.instance
      .collection('restaurants');
  final CollectionReference dishCollection = FirebaseFirestore.instance
      .collection('dishes');

  // --- МЕТОДЫ ДЛЯ ПОЛЬЗОВАТЕЛЕЙ ---
  AppUser _appUserFromSnapshot(DocumentSnapshot snapshot) {
    return AppUser.fromMap(snapshot.data() as Map<String, dynamic>);
  }

  Stream<AppUser> get userData {
    if (uid == null || uid!.isEmpty) {
      return Stream.value(EmptyUser.appUser);
    }
    return userCollection.doc(uid).snapshots().map(_appUserFromSnapshot);
  }

  Future<void> updateUserAddresses(List<DeliveryAddress> addresses) async {
    if (uid == null || uid!.isEmpty) return;
    final addressesMap = addresses.map((addr) => addr.toMap()).toList();
    return await userCollection.doc(uid!).update({'addresses': addressesMap});
  }

  // --- МЕТОДЫ ДЛЯ РЕСТОРАНОВ ---

  Stream<List<Restaurant>> get restaurants {
    return restaurantCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(_restaurantListFromSnapshot);
  }

  // ✅ ВОТ ЭТОТ МЕТОД БЫЛ ПРОПУЩЕН. ТЕПЕРЬ ОН НА МЕСТЕ.
  // Получить рестораны по категории
  Stream<List<Restaurant>> getRestaurantsByCuisine(String cuisine) {
    return restaurantCollection
        .where('isActive', isEqualTo: true)
        .where('cuisineType', arrayContains: cuisine)
        .snapshots()
        .map(_restaurantListFromSnapshot);
  }

  List<Restaurant> _restaurantListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) => _restaurantFromSnapshot(doc)).toList();
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

  // --- МЕТОДЫ ДЛЯ БЛЮД ---

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

  // --- МЕТОДЫ ДЛЯ ИЗБРАННОГО ---

  Future<void> addToFavorites(String restaurantId) async {
    if (uid == null || uid!.isEmpty) return;
    return await userCollection.doc(uid!).update({
      'favorites': FieldValue.arrayUnion([restaurantId]),
    });
  }

  Future<void> removeFromFavorites(String restaurantId) async {
    if (uid == null || uid!.isEmpty) return;
    return await userCollection.doc(uid!).update({
      'favorites': FieldValue.arrayRemove([restaurantId]),
    });
  }

  Stream<List<Restaurant>> get favoriteRestaurants {
    if (uid == null || uid!.isEmpty) return Stream.value([]);
    return userCollection.doc(uid!).snapshots().asyncMap((userSnapshot) async {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final favoriteIds = List<String>.from(userData?['favorites'] ?? []);
      if (favoriteIds.isEmpty) return [];

      final restaurantsSnapshot = await restaurantCollection
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .where('isActive', isEqualTo: true)
          .get();

      return restaurantsSnapshot.docs
          .map((doc) => _restaurantFromSnapshot(doc))
          .toList();
    });
  }

  Stream<bool> isRestaurantFavorite(String restaurantId) {
    if (uid == null || uid!.isEmpty) return Stream.value(false);
    return userCollection.doc(uid!).snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      final favorites = List<String>.from(data?['favorites'] ?? []);
      return favorites.contains(restaurantId);
    });
  }
}
