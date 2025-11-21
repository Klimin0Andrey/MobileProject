import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadAvatarAsBase64({
    required XFile imageFile,
    required String uid,
  }) async {
    try {
      // Сжимаем изображение.
      // minWidth/minHeight автоматически сохраняют пропорции.
      // quality: 70 — оптимальный баланс размера и качества для аватарки.
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 300,  // Уменьшили с 600 до 300 (для аватарки более чем достаточно)
        minHeight: 300,
        quality: 70,    // Немного уменьшили качество (было 85), визуально не заметно, но вес меньше
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        throw Exception('Не удалось сжать изображение.');
      }

      // Кодируем в Base64
      final String base64Image = base64Encode(compressedBytes);
      final String dataUrl = 'data:image/jpeg;base64,$base64Image';

      // Сохраняем
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': dataUrl,
      });

      print('Аватар успешно обновлен. Размер: ${(base64Image.length / 1024).toStringAsFixed(2)} KB');

    } catch (e) {
      print('Ошибка при обработке аватара: $e');
      rethrow;
    }
  }
}