// // lib/services/storage_service.dart
// // Перешли на Cloudinary
// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class StorageService {
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Метод для загрузки аватара
//   Future<String?> uploadAvatar({
//     required File imageFile,
//     required String uid,
//   }) async {
//     try {
//       // 1. Создаем ссылку на место в Storage, куда будем загружать файл
//       // Пример пути: /avatars/user_uid/timestamp.jpg
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final storageRef = _storage.ref().child('avatars/$uid/$timestamp.jpg');
//
//       // 2. Загружаем файл
//       final uploadTask = storageRef.putFile(imageFile);
//
//       // 3. Ждем завершения загрузки
//       final snapshot = await uploadTask.whenComplete(() => {});
//
//       // 4. Получаем URL для скачивания загруженного файла
//       final downloadUrl = await snapshot.ref.getDownloadURL();
//
//       // 5. Сохраняем этот URL в профиле пользователя в Firestore
//       await _firestore.collection('users').doc(uid).update({
//         'avatarUrl': downloadUrl,
//       });
//
//       return downloadUrl;
//     } on FirebaseException catch (e) {
//       print('Ошибка при загрузке аватара: $e');
//       return null;
//     }
//   }
// }