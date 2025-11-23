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
        title: const Text('Обращения в поддержку'),
      ),
      body: Column(
        children: [
          // Фильтры
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
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
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyMessage(_selectedFilter),
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
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
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final statusColor = _getStatusColor(ticket.status);
    final statusText = _getStatusText(ticket.status);
    final hasUnread = ticket.hasUnreadReply;
    final messageCount = ticket.messages.length;
    final lastMessage = ticket.lastMessage;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: hasUnread ? 4 : 1,
      color: hasUnread ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminChatScreen(ticketId: ticket.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (hasUnread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (hasUnread) const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ticket.subject,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📧 ${ticket.userEmail}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
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
              const SizedBox(height: 8),
              if (lastMessage != null) ...[
                Text(
                  '💬 ${lastMessage.text}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💬 $messageCount сообщений',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '⏰ ${dateFormat.format(ticket.createdAtDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
