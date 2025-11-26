import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/support_ticket.dart';
import 'package:linux_test2/services/support_service.dart';
import 'package:linux_test2/presentation/screens/admin/admin_chat_screen.dart';
import 'package:intl/intl.dart';

class AdminTicketsListScreen extends StatefulWidget {
  const AdminTicketsListScreen({super.key});

  @override
  State<AdminTicketsListScreen> createState() => _AdminTicketsListScreenState();
}

class _AdminTicketsListScreenState extends State<AdminTicketsListScreen> {
  final SupportService _supportService = SupportService();
  String _selectedFilter = 'Все';

  final List<String> _filters = ['Все', 'Новые', 'В работе', 'Закрытые'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поддержка'),
      ),
      body: Column(
        children: [
          // ✅ УЛУЧШЕН: Фильтры с ChoiceChip
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: Colors.orange,
                  backgroundColor: Theme.of(context).cardColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    }
                  },
                );
              },
            ),
          ),

          // Список тикетов
          Expanded(
            child: StreamBuilder<List<SupportTicket>>(
              stream: _supportService.getAllTickets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }

                final allTickets = snapshot.data ?? [];
                final filteredTickets = _filterTickets(allTickets, _selectedFilter);

                if (filteredTickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyMessage(_selectedFilter),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredTickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(filteredTickets[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<SupportTicket> _filterTickets(List<SupportTicket> tickets, String filter) {
    switch (filter) {
      case 'Новые':
        return tickets.where((t) => t.status == SupportTicket.statusOpen).toList();
      case 'В работе':
        return tickets.where((t) => t.status == SupportTicket.statusInProgress).toList();
      case 'Закрытые':
        return tickets.where((t) => t.status == SupportTicket.statusResolved).toList();
      default:
        return tickets;
    }
  }

  String _getEmptyMessage(String filter) {
    switch (filter) {
      case 'Новые':
        return 'Нет новых обращений';
      case 'В работе':
        return 'Нет обращений в работе';
      case 'Закрытые':
        return 'Нет закрытых обращений';
      default:
        return 'Нет обращений';
    }
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final dateFormat = DateFormat('dd.MM HH:mm');
    final statusColor = _getStatusColor(ticket.status);
    final statusText = _getStatusText(ticket.status);
    final hasUnread = ticket.hasUnreadReply;

    // ✅ ДОБАВЛЕНО: Цвета для темной темы
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasUnread
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminChatScreen(ticketId: ticket.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.userEmail,
                          style: TextStyle(fontSize: 12, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (ticket.lastMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.lastMessage!.text,
                    style: TextStyle(fontSize: 14, color: textColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message_outlined, size: 16, color: subTextColor),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.messages.length}',
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                    ],
                  ),
                  Text(
                    dateFormat.format(ticket.createdAtDate),
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case SupportTicket.statusOpen:
        return Colors.orange;
      case SupportTicket.statusInProgress:
        return Colors.blue;
      case SupportTicket.statusResolved:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case SupportTicket.statusOpen:
        return 'Новое';
      case SupportTicket.statusInProgress:
        return 'В работе';
      case SupportTicket.statusResolved:
        return 'Закрыто';
      default:
        return status;
    }
  }
}








