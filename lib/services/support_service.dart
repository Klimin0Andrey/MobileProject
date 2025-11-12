import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/support_ticket.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitSupportTicket({
    required String userId,
    required String userName,
    required String userEmail,
    required String category,
    required String subject,
    required String message,
  }) async {
    try {
      // Создаем новый документ в коллекции support_tickets
      final docRef = await _firestore.collection('support_tickets').add({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'category': category,
        'subject': subject,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(), // Используем serverTimestamp
        'adminReply': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Тикет успешно создан с ID: ${docRef.id}');

    } catch (e) {
      print('❌ Ошибка при создании тикета: $e');
      throw Exception('Ошибка при отправке обращения: $e');
    }
  }

  // Метод для загрузки тикетов пользователя
  Stream<List<SupportTicket>> getUserTickets(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SupportTicket.fromFirestore(doc))
        .toList());
  }

  // Метод для получения конкретного тикета
  Future<SupportTicket?> getTicket(String ticketId) async {
    try {
      final doc = await _firestore.collection('support_tickets').doc(ticketId).get();
      if (doc.exists) {
        return SupportTicket.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка при загрузке обращения: $e');
    }
  }
}