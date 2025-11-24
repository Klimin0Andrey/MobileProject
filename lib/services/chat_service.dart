import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Отправка сообщения в чат заказа
  Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String senderName,
    required String role, // 'customer' или 'courier'
    required String text,
  }) async {
    try {
      await _firestore
          .collection('order_chats')
          .doc(orderId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'senderName': senderName,
        'role': role,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Обновляем мета-данные чата (для списка чатов, если понадобится)
      await _firestore.collection('order_chats').doc(orderId).set({
        'orderId': orderId,
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Сообщение отправлено в чат заказа $orderId');
    } catch (e) {
      print('❌ Ошибка отправки сообщения: $e');
      rethrow;
    }
  }

  /// Получение потока сообщений для заказа
  Stream<List<ChatMessage>> getMessages(String orderId) {
    return _firestore
        .collection('order_chats')
        .doc(orderId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Старые сверху, новые снизу
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  /// Получить количество непрочитанных сообщений (опционально, для будущего)
  Future<int> getUnreadCount(String orderId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('order_chats')
          .doc(orderId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}