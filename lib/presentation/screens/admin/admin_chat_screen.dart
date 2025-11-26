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

  @override
  void initState() {
    super.initState();
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
    return StreamBuilder<SupportTicket?>(
      stream: _supportService.getTicketStream(widget.ticketId),
      builder: (context, snapshot) {
        final ticket = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Загрузка...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ошибка')),
            body: Center(child: Text('Ошибка: ${snapshot.error}')),
          );
        }

        if (ticket == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Чат')),
            body: const Center(child: Text('Тикет не найден или удален')),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToBottom();
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.subject),
                Text(
                  ticket.userEmail,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            actions: [
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
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.more_vert),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Инфо-панель
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade100,
                child: Text(
                  'Категория: ${ticket.category} • Создано: ${DateFormat('dd.MM HH:mm').format(ticket.createdAtDate)} • Статус: ${_getStatusText(ticket.status)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),

              // Список сообщений
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: ticket.messages.length,
                  itemBuilder: (context, index) {
                    final message = ticket.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),

              // Поле ввода с проверкой статуса
              _buildInputArea(ticket),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea(SupportTicket ticket) {
    // ✅ Проверяем статус тикета
    if (ticket.status == SupportTicket.statusResolved) {
      // Тикет закрыт - показываем информационное сообщение
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey.shade200,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: isDark ? Colors.grey[400] : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Тикет закрыт',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Чтобы написать сообщение, измените статус на "В работе" или "Открыто"',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Тикет открыт - показываем обычное поле ввода
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Ответ поддержки...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey.shade100,
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
      // ✅ Дополнительная проверка: получаем текущий статус тикета
      final ticketSnapshot = await _supportService.getTicketStream(widget.ticketId).first;
      if (ticketSnapshot?.status == SupportTicket.statusResolved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нельзя отправить сообщение в закрытый тикет'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      _messageController.clear();
      await _supportService.sendAdminMessage(
        ticketId: widget.ticketId,
        text: text,
      );
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
          const SnackBar(content: Text('Статус обновлен'), duration: Duration(seconds: 1)),
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



