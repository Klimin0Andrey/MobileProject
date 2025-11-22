import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/data/models/support_ticket.dart';
import 'package:linux_test2/data/models/support_message.dart';
import 'package:linux_test2/presentation/providers/support_provider.dart';
import 'package:linux_test2/presentation/screens/customer/support_ticket_detail_screen.dart';
import 'package:linux_test2/presentation/screens/customer/support_chat_screen.dart';

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  // Вспомогательные методы для цветов и текстов
  String _getStatusText(String status) {
    switch (status) {
      case 'open': return 'Открыт';
      case 'in_progress': return 'В работе';
      case 'resolved': return 'Решен';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getCategoryText(String category) {
    switch (category) {
      case 'general': return 'Общий вопрос';
      case 'order': return 'Заказ';
      case 'payment': return 'Оплата';
      case 'technical': return 'Техническая проблема';
      case 'other': return 'Другое';
      default: return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мои обращения'), backgroundColor: Colors.orange),
        body: const Center(child: Text('Войдите в систему')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('История обращений'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      // ✅ ИСПОЛЬЗУЕМ StreamBuilder ДЛЯ ПОЛУЧЕНИЯ ДАННЫХ
      body: StreamBuilder<List<SupportTicket>>(
        stream: Provider.of<SupportProvider>(context, listen: false).getUserTicketsStream(user.uid),
        builder: (context, snapshot) {
          // 1. Загрузка
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          // 2. Ошибка
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          // 3. Нет данных
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('У вас пока нет обращений', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final tickets = snapshot.data!;

          // 4. Список тикетов
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupportChatScreen(ticketId: ticket.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Статус (Плашка)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(ticket.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _getStatusColor(ticket.status).withOpacity(0.5)),
                              ),
                              child: Text(
                                _getStatusText(ticket.status),
                                style: TextStyle(
                                  color: _getStatusColor(ticket.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Дата
                            Text(
                              DateFormat('dd.MM.yy').format(ticket.createdAtDate),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ticket.subject,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoryText(ticket.category),
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        // Если есть ответ админа, покажем иконку
                        if (ticket.adminReply != null && ticket.adminReply!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Получен ответ',
                                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}