import 'package:cloud_firestore/cloud_firestore.dart';
// ✅ ИМПОРТИРУЕМ МОДЕЛИ, А НЕ ПЕРЕСОЗДАЕМ ИХ
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
        'messages': [firstMessage.toMap()],
        'isReplyRead': true,
      });
    } catch (e) {
      throw Exception('Ошибка при отправке обращения: $e');
    }
  }

  // Стрим списка тикетов (для юзера)
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

  // Стрим одного тикета (для чата в реальном времени)
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

  // Отправка сообщения в чат
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

    currentMessages.add(newMessage.toMap());

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

  // ✅ ИСПРАВЛЕНО: Теперь метод знает, КТО читает сообщения
  Future<void> markMessagesAsRead(String ticketId, {required bool isAdmin}) async {
    final docRef = _firestore.collection('support_tickets').doc(ticketId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> messagesData = data['messages'] ?? [];

      bool hasChanges = false;
      final List<Map<String, dynamic>> updatedMessages = [];

      // Если я Админ -> я читаю сообщения от 'user'
      // Если я Юзер -> я читаю сообщения от 'admin'
      final targetSender = isAdmin ? 'user' : 'admin';

      for (var msgMap in messagesData) {
        final msg = Map<String, dynamic>.from(msgMap as Map);
        final senderStr = msg['sender'].toString();

        // Проверяем, содержит ли отправитель целевую роль
        if (senderStr.contains(targetSender) && (msg['isRead'] == false)) {
          msg['isRead'] = true;
          hasChanges = true;
        }
        updatedMessages.add(msg);
      }

      if (hasChanges) {
        final updateData = <String, dynamic>{
          'messages': updatedMessages,
        };

        // Сбрасываем флаг быстрого уведомления для клиента
        if (!isAdmin) {
          updateData['isReplyRead'] = true;
        }

        transaction.update(docRef, updateData);
      }
    });
  }

  // Для совместимости
  Future<void> markReplyAsRead(String ticketId) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'isReplyRead': true,
    });
  }

  // Получение всех тикетов (для админа)
  Stream<List<SupportTicket>> getAllTickets() {
    return _firestore
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SupportTicket.fromFirestore(doc))
        .toList());
  }

  // Обновление статуса тикета
  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _firestore.collection('support_tickets').doc(ticketId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // При отправке сообщения админом автоматически меняем статус
  Future<void> sendAdminMessage({
    required String ticketId,
    required String text,
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
      sender: MessageSender.admin,
      createdAt: Timestamp.now(),
      isRead: false, // Пользователь еще не прочитал
    );

    currentMessages.add(newMessage.toMap());

    final updateData = <String, dynamic>{
      'messages': currentMessages,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Если статус был 'open', меняем на 'in_progress'
    final currentStatus = ticketSnapshot.data()?['status'] as String? ?? 'open';
    if (currentStatus == 'open') {
      updateData['status'] = 'in_progress';
    }

    await ticketDoc.update(updateData);
  }
}