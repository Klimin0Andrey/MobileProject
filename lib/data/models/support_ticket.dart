import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String message;
  final Timestamp createdAt; // ИЗМЕНИЛИ: DateTime → Timestamp
  final String status; // 'open', 'in_progress', 'resolved'
  final String? adminReply;
  final String category;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.message,
    required this.createdAt, // Теперь принимает Timestamp
    required this.category,
    this.status = 'open',
    this.adminReply,
  });

  // Константы для статусов
  static const String statusOpen = 'open';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved = 'resolved';

  // toMap метод - ДЛЯ СОХРАНЕНИЯ В FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'subject': subject,
      'message': message,
      'category': category,
      'createdAt': createdAt, // Уже Timestamp, не конвертируем
      'status': status,
      'adminReply': adminReply,
    };
  }

  // fromMap метод - ДЛЯ ЧТЕНИЯ ИЗ FIRESTORE
  factory SupportTicket.fromMap(Map<String, dynamic> map, String documentId) {
    return SupportTicket(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      category: map['category'] ?? 'general',
      createdAt: map['createdAt'] ?? Timestamp.now(), // Получаем Timestamp
      status: map['status'] ?? 'open',
      adminReply: map['adminReply'],
    );
  }

  // fromFirestore метод для удобной работы с Firebase
  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicket(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? 'general',
      createdAt: data['createdAt'] ?? Timestamp.now(), // Получаем Timestamp
      status: data['status'] ?? 'open',
      adminReply: data['adminReply'],
    );
  }

  // Дополнительный геттер для удобства, если нужен DateTime
  DateTime get createdAtDate => createdAt.toDate();
}