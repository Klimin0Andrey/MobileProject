// lib/services/image_service.dart

import 'dart:convert';
import 'dart:typed_data'; // Необходимо для работы с байтами
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
// Импортируем пакет 'image' с префиксом 'img', чтобы избежать конфликтов имен
import 'package:image/image.dart' as img;

class ImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadAvatarAsBase64({
    required XFile imageFile,
    required String uid,
  }) async {
    try {
      // 1. Читаем байты из файла
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 2. Декодируем байты в объект изображения с помощью пакета 'image'
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Не удалось обработать изображение.');
      }

      // 3. Изменяем размер изображения, чтобы оно было не больше 600x600 пикселей.
      // Пакет сам сохраняет соотношение сторон.
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: 600,
        height: 600,
      );

      // 4. Кодируем измененное изображение обратно в байты формата JPG с качеством 85%.
      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 85),
      );

      // 5. Кодируем сжатые байты в строку Base64
      final String base64Image = base64Encode(compressedBytes);
      final String dataUrl = 'data:image/jpeg;base64,$base64Image';

      // 6. Сохраняем строку в Firestore
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': dataUrl,
      });

      print('Аватар успешно обновлен для пользователя: $uid');

    } catch (e) {
      print('Ошибка при обработке и сохранении аватара: $e');
      rethrow;
    }
  }
}