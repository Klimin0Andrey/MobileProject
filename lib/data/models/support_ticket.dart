import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/support_message.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String message; // Первое сообщение пользователя
  final Timestamp createdAt;
  final String status;
  final String? adminReply; // ✅ ОСТАВЛЯЕМ для обратной совместимости
  final String category;
  final bool isReplyRead;
  final List<SupportMessage> messages; // ✅ ДОБАВЛЕНО: массив сообщений диалога

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.message,
    required this.createdAt,
    required this.category,
    this.status = 'open',
    this.adminReply,
    this.isReplyRead = true,
    this.messages = const [], // ✅ ДОБАВЛЕНО
  });

  // Константы для статусов
  static const String statusOpen = 'open';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved = 'resolved';

  // toMap метод
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'subject': subject,
      'message': message,
      'category': category,
      'createdAt': createdAt,
      'status': status,
      'adminReply': adminReply, // Оставляем для обратной совместимости
      'isReplyRead': isReplyRead,
      'messages': messages.map((msg) => msg.toMap()).toList(), // ✅ ДОБАВЛЕНО
    };
  }

  // fromMap метод
  factory SupportTicket.fromMap(Map<String, dynamic> map, String documentId) {
    // ✅ ДОБАВЛЕНО: Парсинг сообщений
    List<SupportMessage> messagesList = [];
    if (map['messages'] != null && map['messages'] is List) {
      final messagesData = map['messages'] as List;
      messagesList = messagesData.asMap().entries.map((entry) {
        return SupportMessage.fromMap(
          entry.value as Map<String, dynamic>,
          entry.key.toString(),
        );
      }).toList();
    }

    return SupportTicket(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      category: map['category'] ?? 'general',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      status: map['status'] ?? 'open',
      adminReply: map['adminReply'],
      isReplyRead: map['isReplyRead'] ?? true,
      messages: messagesList, // ✅ ДОБАВЛЕНО
    );
  }

  // fromFirestore метод
  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // ✅ ДОБАВЛЕНО: Парсинг сообщений
    List<SupportMessage> messagesList = [];
    if (data['messages'] != null && data['messages'] is List) {
      final messagesData = data['messages'] as List;
      messagesList = messagesData.asMap().entries.map((entry) {
        return SupportMessage.fromMap(
          entry.value as Map<String, dynamic>,
          entry.key.toString(),
        );
      }).toList();
    }

    return SupportTicket(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? 'general',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'open',
      adminReply: data['adminReply'],
      isReplyRead: data['isReplyRead'] ?? true,
      messages: messagesList, // ✅ ДОБАВЛЕНО
    );
  }

  DateTime get createdAtDate => createdAt.toDate();
  
  // ✅ ОБНОВЛЕНО: Проверка непрочитанных ответов
  bool get hasUnreadReply {
    // Проверяем новые сообщения от админа
    return messages.any((msg) => 
      msg.sender == MessageSender.admin && !msg.isRead
    ) || (adminReply != null && adminReply!.isNotEmpty && !isReplyRead);
  }
  
  // ✅ ДОБАВЛЕНО: Получить последнее сообщение
  SupportMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }
}