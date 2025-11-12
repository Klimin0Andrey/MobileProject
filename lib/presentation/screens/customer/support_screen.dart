import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
//import 'package:linux_test2/services/support_service.dart';
import 'package:linux_test2/presentation/providers/support_provider.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'general';
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitSupportRequest(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AppUser?>();
    if (user == null) {
      _showAuthDialog(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<SupportProvider>().submitTicket(
        userId: user.uid,
        userName: user.email.split('@').first,
        userEmail: user.email,
        category: _selectedCategory,
        subject: _subjectController.text,
        message: _messageController.text,
      );

      // Очищаем форму
      _subjectController.clear();
      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ваше обращение отправлено! Мы ответим в течение 24 часов.'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при отправке: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется авторизация'),
        content: const Text('Для обращения в поддержку необходимо войти в аккаунт'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Навигация на экран авторизации
              // Navigator.pushNamed(context, '/login');
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Частые вопросы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              question: 'Как отследить заказ?',
              answer: 'Статус заказа можно отслеживать в разделе "История заказов" в вашем профиле. Там вы увидите все детали заказа и его текущий статус.',
            ),
            _buildFaqItem(
              question: 'Какие способы оплаты доступны?',
              answer: 'Мы принимаем банковские карты (Visa, MasterCard, МИР) для онлайн-оплаты, а также наличные при получении заказа.',
            ),
            _buildFaqItem(
              question: 'Как изменить адрес доставки?',
              answer: 'Адрес доставки можно изменить в корзине до подтверждения заказа. После подтверждения свяжитесь с поддержкой для изменения адреса.',
            ),
            _buildFaqItem(
              question: 'Что делать, если я получил неверный заказ?',
              answer: 'Немедленно свяжитесь с нами по телефону поддержки или через эту форму. Сохраните заказ и приложите фото для быстрого решения проблемы.',
            ),
            _buildFaqItem(
              question: 'Как отменить заказ?',
              answer: 'Заказ можно отменить в разделе "История заказов" если он еще не принят рестораном. Для отмены принятого заказа свяжитесь с поддержкой.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Обращение в поддержку',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Если вы не нашли ответ на свой вопрос в разделе выше, заполните форму ниже и мы обязательно вам поможем.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Категория обращения
              const Text(
                'Категория вопроса *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: const [
                  DropdownMenuItem(
                    value: 'general',
                    child: Text('Общий вопрос'),
                  ),
                  DropdownMenuItem(
                    value: 'order',
                    child: Text('Проблема с заказом'),
                  ),
                  DropdownMenuItem(
                    value: 'payment',
                    child: Text('Оплата'),
                  ),
                  DropdownMenuItem(
                    value: 'technical',
                    child: Text('Техническая проблема'),
                  ),
                  DropdownMenuItem(
                    value: 'refund',
                    child: Text('Возврат средств'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Другое'),
                  ),
                ],
                onChanged: _isLoading ? null : (value) {
                  setState(() => _selectedCategory = value!);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите категорию вопроса';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Тема
              TextFormField(
                controller: _subjectController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Тема обращения *',
                  border: OutlineInputBorder(),
                  hintText: 'Кратко опишите суть проблемы',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите тему обращения';
                  }
                  if (value.length < 5) {
                    return 'Тема должна содержать минимум 5 символов';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Сообщение
              TextFormField(
                controller: _messageController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Подробное описание проблемы *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: 'Опишите вашу проблему максимально подробно...',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Опишите вашу проблему';
                  }
                  if (value.length < 10) {
                    return 'Описание должно содержать минимум 10 символов';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),
              Text(
                'Минимум 10 символов',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 24),

              // Кнопка отправки
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitSupportRequest(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Отправить обращение',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Контактная информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.phone,
              title: 'Телефон поддержки',
              subtitle: '+7 (999) 123-45-67',
              onTap: () {
                // TODO: Реализовать звонок
              },
            ),
            _buildContactItem(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'support@yumyum.ru',
              onTap: () {
                // TODO: Реализовать отправку email
              },
            ),
            _buildContactItem(
              icon: Icons.access_time,
              title: 'Время работы',
              subtitle: 'Круглосуточно, 24/7',
            ),
            _buildContactItem(
              icon: Icons.chat,
              title: 'Онлайн-чат',
              subtitle: 'Доступен в мобильном приложении',
              onTap: () {
                _showComingSoonDialog(context, 'Онлайн-чат');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скоро будет доступно'),
        content: Text('Функция "$feature" находится в разработке'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь и поддержка'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFaqSection(),
          const SizedBox(height: 24),
          _buildContactSection(context),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Обычно мы отвечаем на обращения в течение 1-2 часов в рабочее время',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}