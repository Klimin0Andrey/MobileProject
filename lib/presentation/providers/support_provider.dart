import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/support_ticket.dart';
import 'package:linux_test2/services/support_service.dart';

class SupportProvider with ChangeNotifier {
  final List<SupportTicket> _tickets = [];
  final SupportService _supportService = SupportService();

  List<SupportTicket> get tickets => _tickets;

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

      // После успешной отправки перезагружаем тикеты
      await loadUserTickets(userId);

    } catch (e) {
      throw Exception('Ошибка при отправке обращения: $e');
    }
  }

  Future<void> loadUserTickets(String userId) async {
    try {
      // TODO: Реализовать метод в SupportService для загрузки тикетов пользователя
      // _tickets = await _supportService.getUserTickets(userId);
      notifyListeners();
    } catch (e) {
      throw Exception('Ошибка при загрузке обращений: $e');
    }
  }

  void clearTickets() {
    _tickets.clear();
    notifyListeners();
  }
}