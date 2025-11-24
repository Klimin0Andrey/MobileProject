import 'package:flutter/material.dart';
import 'package:linux_test2/data/models/support_ticket.dart';
import 'package:linux_test2/data/models/support_message.dart';
import 'package:linux_test2/services/support_service.dart';
import 'package:intl/intl.dart';

class AdminChatScreen extends StatefulWidget {
  final String ticketId;

  const AdminChatScreen({super.key, required this.ticketId});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final SupportService _supportService = SupportService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SupportTicket? _ticket;

  @override
  void initState() {
    super.initState();
    // ✅ ВАЖНО: Помечаем сообщения пользователя как прочитанные при открытии чата админом
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markAsRead() {
    // Передаем isAdmin: true, чтобы сервис понял, что читает админ
    _supportService.markMessagesAsRead(widget.ticketId, isAdmin: true);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_ticket?.subject ?? 'Чат поддержки'),
            if (_ticket != null)
              Text(
                _ticket!.userEmail,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (_ticket != null)
            PopupMenuButton<String>(
              tooltip: 'Изменить статус',
              onSelected: (value) => _updateStatus(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SupportTicket.statusOpen,
                  child: Text('Открыто'),
                ),
                const PopupMenuItem(
                  value: SupportTicket.statusInProgress,
                  child: Text('В работе'),
                ),
                const PopupMenuItem(
                  value: SupportTicket.statusResolved,
                  child: Text('Закрыто'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(Icons.more_vert),
              ),
            ),
        ],
      ),
      body: StreamBuilder<SupportTicket?>(
        stream: _supportService.getTicketStream(widget.ticketId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          _ticket = snapshot.data;
          if (_ticket == null) {
            return const Center(child: Text('Тикет не найден или удален'));
          }

          // Автопрокрутка вниз при новых сообщениях
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollToBottom();
            }
          });

          return Column(
            children: [
              // Инфо-панель с категорией и датой
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade100,
                child: Text(
                  'Категория: ${_ticket!.category} • Создано: ${DateFormat('dd.MM HH:mm').format(_ticket!.createdAtDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),

              // Список сообщений
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _ticket!.messages.length,
                  itemBuilder: (context, index) {
                    final message = _ticket!.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),

              // Поле ввода
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ответ поддержки...',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message) {
    final isAdmin = message.sender == MessageSender.admin;
    final dateFormat = DateFormat('HH:mm');

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isAdmin ? const Radius.circular(16) : Radius.zero,
            bottomRight: isAdmin ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: isAdmin ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  dateFormat.format(message.createdAt.toDate()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isAdmin ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 4),
                  Icon(
                    // Галочки: одна если отправлено, две если прочитано клиентом
                    message.isRead ? Icons.done_all : Icons.check,
                    size: 12,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      _messageController.clear();

      await _supportService.sendAdminMessage(
        ticketId: widget.ticketId,
        text: text,
      );

      // Помечаем входящие сообщения как прочитанные
      _markAsRead();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _supportService.updateTicketStatus(widget.ticketId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Статус обновлен'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}


