import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:linux_test2/config/cloudinary_config.dart'; // Проверь, чтобы путь совпадал с твоим проектом!

class ImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================================================
  // 1. АВАТАРКИ ПОЛЬЗОВАТЕЛЕЙ (User Avatars)
  // =========================================================

  /// Загружает аватар пользователя в Cloudinary
  Future<String> uploadAvatar({
    required XFile imageFile,
    required String uid,
  }) async {
    try {
      // 1. Сжимаем (для аватарки качество 70 достаточно)
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 300,
        minHeight: 300,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) throw Exception('Не удалось сжать изображение.');

      // 2. Загружаем с пресетом 'avatar_upload'
      final imageUrl = await _uploadToCloudinary(
        imageBytes: compressedBytes,
        uploadPreset: CloudinaryConfig.avatarUploadPreset,
        folder: 'avatars',
        publicId: 'avatar_$uid',
      );

      // 3. Обновляем ссылку в Firestore ПЕРЕД удалением старого
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Удаляем старый аватар ПОСЛЕ успешного обновления
      // (на самом деле, Cloudinary сам перезапишет файл с тем же public_id,
      // но можно оставить для очистки старых версий)
      await _deleteFromCloudinary('avatars/avatar_$uid');

      print('✅ Аватар загружен: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('❌ Ошибка uploadAvatar: $e');
      rethrow;
    }
  }

  // =========================================================
  // 2. ЕДА / ТОВАРЫ (Food Products) - НОВОЕ!
  // =========================================================

  /// Загружает фото еды (для Админки)
  /// Возвращает ссылку (String), которую надо сохранить в Firestore
  Future<String> uploadProductImage({
    required XFile imageFile,
    String? productId, // Если ID нет, сгенерируем временный
  }) async {
    try {
      // Генерируем ID, если не передан
      final String uniqueId = productId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // 1. Сжимаем (для еды качество повыше - 85, и размер побольше)
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) throw Exception('Не удалось сжать изображение.');

      // 2. Загружаем с пресетом 'food_upload'
      final imageUrl = await _uploadToCloudinary(
        imageBytes: compressedBytes,
        uploadPreset: CloudinaryConfig.foodUploadPreset,
        folder: 'food',
        publicId: 'food_$uniqueId',
      );

      print('🍔 Фото еды загружено: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('❌ Ошибка uploadProductImage: $e');
      rethrow;
    }
  }

  // =========================================================
  // 3. РЕСТОРАНЫ (Restaurants) - НОВОЕ!
  // =========================================================

  /// Загружает фото ресторана (для Админки)
  Future<String> uploadRestaurantImage({
    required XFile imageFile,
    required String restaurantId,
  }) async {
    try {
      // 1. Сжимаем (Рестораны можно чуть шире, например 800x600)
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 800,
        minHeight: 600,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) throw Exception('Не удалось сжать изображение.');

      // 2. Загружаем с пресетом 'restaurant_upload'
      final imageUrl = await _uploadToCloudinary(
        imageBytes: compressedBytes,
        uploadPreset: CloudinaryConfig.restaurantUploadPreset,
        folder: 'restaurants',
        publicId: 'rest_$restaurantId',
      );

      print('🏪 Фото ресторана загружено: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('❌ Ошибка uploadRestaurantImage: $e');
      rethrow;
    }
  }

  // =========================================================
  // ВНУТРЕННИЕ МЕТОДЫ (Private Helpers)
  // =========================================================

  /// Универсальный метод загрузки в Cloudinary
  Future<String> _uploadToCloudinary({
    required Uint8List imageBytes,
    required String uploadPreset,
    required String folder,
    required String publicId,
  }) async {
    try {
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      // Параметры для Unsigned загрузки
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      request.fields['public_id'] = publicId;
      // request.fields['overwrite'] = 'true'; // Перезаписывать старое

      // Файл
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: 'upload.jpg'),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception('Cloudinary Error ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      print('❌ Ошибка сети Cloudinary: $e');
      rethrow;
    }
  }

  /// Удаляет изображение (требует подписи)
  Future<void> _deleteFromCloudinary(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateDeleteSignature(
        publicId: publicId,
        timestamp: timestamp,
      );

      final response = await http.post(
        Uri.parse(CloudinaryConfig.destroyUrl),
        body: {
          'public_id': publicId,
          'api_key': CloudinaryConfig.apiKey,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        print('🗑️ Удалено из облака: $publicId');
      } else {
        print('⚠️ Ошибка удаления: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Исключение при удалении: $e');
    }
  }

  /// Генерация SHA-1 подписи для удаления
  String _generateDeleteSignature({
    required String publicId,
    required String timestamp,
  }) {
    final signatureString = 'public_id=$publicId&timestamp=$timestamp${CloudinaryConfig.apiSecret}';
    final bytes = utf8.encode(signatureString);
    final hash = sha1.convert(bytes);
    return hash.toString();
  }

  /// Публичный метод для удаления аватара (совместимость)
  Future<void> deleteAvatar(String uid) async {
    await _deleteFromCloudinary('avatars/avatar_$uid');
    await _firestore.collection('users').doc(uid).update({
      'avatarUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // ⚠️ LEGACY / OLD CODE (FIREBASE BASE64)
  // Оставлено для истории, как просили. Не использовать!
  // =========================================================

  // ⚠️ ЗАКОММЕНТИРОВАНО: Старый метод с Base64 (Убивает лимиты Firestore)
  /*
  Future<void> uploadAvatarAsBase64({
    required XFile imageFile,
    required String uid,
  }) async {
    try {
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 300,
        minHeight: 300,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) throw Exception('Ошибка сжатия.');

      final String base64Image = base64Encode(compressedBytes);
      final String dataUrl = 'data:image/jpeg;base64,$base64Image';

      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': dataUrl,
      });

      print('Base64 Upload Success');
    } catch (e) {
      print('Base64 Error: $e');
      rethrow;
    }
  }
  */

  // ⚠️ DEPRECATED: Для обратной совместимости
  @Deprecated('Используйте uploadAvatar вместо uploadAvatarAsBase64')
  Future<void> uploadAvatarAsBase64({
    required XFile imageFile,
    required String uid,
  }) async {
    await uploadAvatar(imageFile: imageFile, uid: uid);
  }
}