import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/support_ticket.dart';
import 'package:linux_test2/data/models/support_message.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Создание тикета
  Future<void> submitSupportTicket({
    required String userId,
    required String userName,
    required String userEmail,
    required String category,
    required String subject,
    required String message,
  }) async {
    try {
      // ✅ ДОБАВЛЕНО: Создаем первое сообщение
      final firstMessage = SupportMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message,
        sender: MessageSender.user,
        createdAt: Timestamp.now(),
        isRead: true,
      );

      await _firestore.collection('support_tickets').add({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'category': category,
        'subject': subject,
        'message': message, // Оставляем для обратной совместимости
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'adminReply': null,
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': [firstMessage.toMap()], // ✅ ДОБАВЛЕНО: первое сообщение
        'isReplyRead': true,
      });
    } catch (e) {
      throw Exception('Ошибка при отправке обращения: $e');
    }
  }

  // Стрим списка тикетов
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

  // Получение одного тикета (Future)
  Future<SupportTicket?> getTicket(String ticketId) async {
    final doc = await _firestore.collection('support_tickets').doc(ticketId).get();
    if (doc.exists) {
      return SupportTicket.fromFirestore(doc);
    }
    return null;
  }

  // ✅ ДОБАВЛЕНО: Стрим одного тикета (для чата в реальном времени)
  Stream<SupportTicket?> getTicketStream(String ticketId) {
    return _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return SupportTicket.fromFirestore(doc);
      }
      return null;
    });
  }

  // ✅ ДОБАВЛЕНО: Отправка сообщения в чат
  Future<void> sendMessage({
    required String ticketId,
    required String text,
    required MessageSender sender,
  }) async {
    final ticketDoc = _firestore.collection('support_tickets').doc(ticketId);
    final ticketSnapshot = await ticketDoc.get();
    
    if (!ticketSnapshot.exists) {
      throw Exception('Тикет не найден');
    }

    final currentMessages = ticketSnapshot.data()?['messages'] as List? ?? [];
    
    final newMessage = SupportMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: sender,
      createdAt: Timestamp.now(),
      isRead: sender == MessageSender.user, // Сообщения пользователя сразу прочитаны
    );

    // Добавляем новое сообщение в массив
    currentMessages.add(newMessage.toMap());

    // ✅ ИСПРАВЛЕНО: Создаем Map отдельно
    final updateData = <String, dynamic>{
      'messages': currentMessages,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // Если это ответ пользователя, обновляем статус
    if (sender == MessageSender.user) {
      updateData['status'] = 'open';
    }

    await ticketDoc.update(updateData);
  }

  // ✅ ДОБАВЛЕНО: Пометить сообщения как прочитанные
  Future<void> markMessagesAsRead(String ticketId) async {
    // Firestore не умеет обновлять элементы массива по условию одной командой.
    // Нужно прочитать документ, обновить массив в памяти и записать обратно.

    final docRef = _firestore.collection('support_tickets').doc(ticketId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> messagesData = data['messages'] ?? [];

      bool hasChanges = false;
      final List<Map<String, dynamic>> updatedMessages = [];

      for (var msgMap in messagesData) {
        final msg = Map<String, dynamic>.from(msgMap as Map);
        // Если сообщение от АДМИНА и оно НЕ прочитано -> читаем его
        if (msg['sender'] == 'admin' && (msg['isRead'] == false)) {
          msg['isRead'] = true;
          hasChanges = true;
        }
        updatedMessages.add(msg);
      }

      if (hasChanges) {
        transaction.update(docRef, {
          'messages': updatedMessages,
          'isReplyRead': true, // Также обновляем старое поле совместимости
        });
      }
    });
  }

  // Для совместимости
  Future<void> markReplyAsRead(String ticketId) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'isReplyRead': true,
    });
  }
}