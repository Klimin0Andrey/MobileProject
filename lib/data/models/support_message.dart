import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSender { user, admin }

class SupportMessage {
  final String id;
  final String text;
  final MessageSender sender; // user или admin
  final Timestamp createdAt;
  final bool isRead;

  SupportMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.isRead = false,
  });

  // Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender == MessageSender.user ? 'user' : 'admin',
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  // Создание из Map
  factory SupportMessage.fromMap(Map<String, dynamic> map, String messageId) {
    return SupportMessage(
      id: messageId,
      text: map['text'] ?? '',
      sender: map['sender'] == 'user' ? MessageSender.user : MessageSender.admin,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  DateTime get createdAtDate => createdAt.toDate();
}
