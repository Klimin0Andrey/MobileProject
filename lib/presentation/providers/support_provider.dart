import 'dart:async';
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/support_ticket.dart';
import 'package:linux_test2/services/support_service.dart';

class SupportProvider with ChangeNotifier {
  final SupportService _supportService = SupportService();
  
  // ✅ ИЗМЕНЕНО: Используем Stream вместо List
  Stream<List<SupportTicket>> getUserTicketsStream(String userId) {
    return _supportService.getUserTickets(userId);
  }

  Future<void> submitTicket({
    required String userId,
    required String userName,
    required String userEmail,
    required String category,
    required String subject,
    required String message,
  }) async {
    try {
      await _supportService.submitSupportTicket(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        category: category,
        subject: subject,
        message: message,
      );
    } catch (e) {
      throw Exception('Ошибка при отправке обращения: $e');
    }
  }

  // ✅ ДОБАВЛЕНО: Метод для получения конкретного тикета
  Future<SupportTicket?> getTicket(String ticketId) async {
    try {
      return await _supportService.getTicket(ticketId);
    } catch (e) {
      throw Exception('Ошибка при загрузке обращения: $e');
    }
  }
}