import 'dart:async';
import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/support_ticket.dart';
import 'package:linux_test2/data/models/support_message.dart';
import 'package:linux_test2/services/support_service.dart';

class SupportProvider with ChangeNotifier {
  final SupportService _supportService = SupportService();
  
  Stream<List<SupportTicket>> getUserTicketsStream(String userId) {
    return _supportService.getUserTickets(userId);
  }

  // ✅ ДОБАВЛЕНО: Получить Stream конкретного тикета
  Stream<SupportTicket?> getTicketStream(String ticketId) {
    return _supportService.getTicketStream(ticketId);
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

  Future<SupportTicket?> getTicket(String ticketId) async {
    try {
      return await _supportService.getTicket(ticketId);
    } catch (e) {
      throw Exception('Ошибка при загрузке обращения: $e');
    }
  }

  // ✅ ДОБАВЛЕНО: Отправить сообщение в тикет
  Future<void> sendMessage({
    required String ticketId,
    required String text,
  }) async {
    try {
      await _supportService.sendMessage(
        ticketId: ticketId,
        text: text,
        sender: MessageSender.user,
      );
    } catch (e) {
      throw Exception('Ошибка при отправке сообщения: $e');
    }
  }

  // ✅ ДОБАВЛЕНО: Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String ticketId) async {
    try {
      await _supportService.markMessagesAsRead(ticketId);
    } catch (e) {
      throw Exception('Ошибка при обновлении статуса прочитанности: $e');
    }
  }

  // Для обратной совместимости
  Future<void> markReplyAsRead(String ticketId) async {
    try {
      await _supportService.markReplyAsRead(ticketId);
    } catch (e) {
      throw Exception('Ошибка при обновлении статуса прочитанности: $e');
    }
  }
}