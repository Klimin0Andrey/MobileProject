import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/data/models/dish.dart';

class AdminMenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ========== РЕСТОРАНЫ ==========

  // Получить все рестораны (включая неактивные)
  Stream<List<Restaurant>> getAllRestaurants() {
    return _firestore
        .collection('restaurants')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _restaurantFromSnapshot(doc))
            .toList());
  }

  // Создать ресторан
  Future<void> createRestaurant({
    required String name,
    required String description,
    required String deliveryTime,
    required List<String> cuisineType,
    String? imageUrl,
  }) async {
    await _firestore.collection('restaurants').add({
      'name': name,
      'description': description,
      'imageUrl': imageUrl ?? '',
      'rating': 0.0,
      'deliveryTime': deliveryTime,
      'cuisineType': cuisineType,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Обновить ресторан
  Future<void> updateRestaurant({
    required String restaurantId,
    String? name,
    String? description,
    String? deliveryTime,
    List<String>? cuisineType,
    String? imageUrl,
    bool? isActive,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (deliveryTime != null) updateData['deliveryTime'] = deliveryTime;
    if (cuisineType != null) updateData['cuisineType'] = cuisineType;
    if (imageUrl != null) updateData['imageUrl'] = imageUrl;
    if (isActive != null) updateData['isActive'] = isActive;
    
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('restaurants').doc(restaurantId).update(updateData);
  }

  // Удалить ресторан (или деактивировать)
  Future<void> deleteRestaurant(String restaurantId, {bool deactivateOnly = true}) async {
    if (deactivateOnly) {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('restaurants').doc(restaurantId).delete();
    }
  }

  // Загрузить изображение ресторана
  Future<String?> uploadRestaurantImage(XFile imageFile, String restaurantId) async {
    try {
      // Сжимаем изображение
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 800,
        minHeight: 600,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        throw Exception('Не удалось сжать изображение');
      }

      // Загружаем в Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage
          .ref()
          .child('restaurants/$restaurantId/$timestamp.jpg');

      final uploadTask = storageRef.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Ошибка при загрузке изображения ресторана: $e');
      return null;
    }
  }

  // ========== БЛЮДА ==========

  // Получить все блюда ресторана (включая недоступные)
  Stream<List<Dish>> getRestaurantDishes(String restaurantId) {
    return _firestore
        .collection('dishes')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('category')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _dishFromSnapshot(doc))
            .toList());
  }

  // Создать блюдо
  Future<void> createDish({
    required String restaurantId,
    required String name,
    required String description,
    required double price,
    required String category,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    await _firestore.collection('dishes').add({
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl ?? '',
      'category': category,
      'isAvailable': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Обновить блюдо
  Future<void> updateDish({
    required String dishId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (price != null) updateData['price'] = price;
    if (category != null) updateData['category'] = category;
    if (imageUrl != null) updateData['imageUrl'] = imageUrl;
    if (isAvailable != null) updateData['isAvailable'] = isAvailable;
    
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('dishes').doc(dishId).update(updateData);
  }

  // Переключить доступность блюда (стоп-лист)
  Future<void> toggleDishAvailability(String dishId, bool isAvailable) async {
    await _firestore.collection('dishes').doc(dishId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Удалить блюдо
  Future<void> deleteDish(String dishId) async {
    await _firestore.collection('dishes').doc(dishId).delete();
  }

  // Загрузить изображение блюда
  Future<String?> uploadDishImage(XFile imageFile, String dishId) async {
    try {
      // Сжимаем изображение
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 600,
        minHeight: 600,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        throw Exception('Не удалось сжать изображение');
      }

      // Загружаем в Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage
          .ref()
          .child('dishes/$dishId/$timestamp.jpg');

      final uploadTask = storageRef.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Ошибка при загрузке изображения блюда: $e');
      return null;
    }
  }

  // ========== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ==========

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
      isActive: data['isActive'] ?? true,
    );
  }

  Dish _dishFromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dish(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  // Получить список категорий блюд
  Future<List<String>> getDishCategories() async {
    final snapshot = await _firestore.collection('dishes').get();
    final categories = <String>{};
    
    for (var doc in snapshot.docs) {
      final category = doc.data()['category'] as String?;
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }
    
    return categories.toList()..sort();
  }

  // Получить список типов кухни
  Future<List<String>> getCuisineTypes() async {
    final snapshot = await _firestore.collection('restaurants').get();
    final cuisineTypes = <String>{};
    
    for (var doc in snapshot.docs) {
      final types = doc.data()['cuisineType'] as List?;
      if (types != null) {
        for (var type in types) {
          if (type is String && type.isNotEmpty) {
            cuisineTypes.add(type);
          }
        }
      }
    }
    
    return cuisineTypes.toList()..sort();
  }
}

