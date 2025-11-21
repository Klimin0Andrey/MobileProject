import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для буфера обмена
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Для звонков и почты
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/presentation/providers/support_provider.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';

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
        userName: user.name.isNotEmpty ? user.name : user.email.split('@').first,
        userEmail: user.email,
        category: _selectedCategory,
        subject: _subjectController.text,
        message: _messageController.text,
      );

      // Очищаем форму
      _subjectController.clear();
      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ваше обращение отправлено! Мы ответим в течение 24 часов.'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при отправке: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 📞 Логика звонка
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showError('Не удалось открыть приложение телефона');
    }
  }

  // 📧 Логика email
  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Вопрос из приложения YumYum',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showError('Не удалось открыть почтовый клиент');
    }
  }

  // 📋 Логика копирования
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label скопирован в буфер обмена'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Authenticate()),
              );
            },
            child: const Text('Войти'),
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
          _buildContactFormSection(context),
          const SizedBox(height: 24),
          _buildContactInfoSection(), // Обновленная секция контактов
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

  Widget _buildContactFormSection(BuildContext context) {
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
                  DropdownMenuItem(value: 'general', child: Text('Общий вопрос')),
                  DropdownMenuItem(value: 'order', child: Text('Проблема с заказом')),
                  DropdownMenuItem(value: 'payment', child: Text('Оплата')),
                  DropdownMenuItem(value: 'technical', child: Text('Техническая проблема')),
                  DropdownMenuItem(value: 'refund', child: Text('Возврат средств')),
                  DropdownMenuItem(value: 'other', child: Text('Другое')),
                ],
                onChanged: _isLoading ? null : (value) {
                  setState(() => _selectedCategory = value!);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Выберите категорию' : null,
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
                  if (value == null || value.isEmpty) return 'Введите тему обращения';
                  if (value.length < 5) return 'Минимум 5 символов';
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
                  if (value == null || value.isEmpty) return 'Опишите вашу проблему';
                  if (value.length < 10) return 'Минимум 10 символов';
                  return null;
                },
              ),

              const SizedBox(height: 8),
              Text(
                'Минимум 10 символов',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  Widget _buildContactInfoSection() {
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

            // Телефон (Звонок + Копирование)
            _buildContactItem(
              icon: Icons.phone,
              title: 'Телефон поддержки',
              subtitle: '+7 (999) 123-45-67',
              onTap: () => _makePhoneCall('+79991234567'),
              onLongPress: () => _copyToClipboard('+79991234567', 'Телефон'),
            ),

            // Email (Почта + Копирование)
            _buildContactItem(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'support@yumyum.ru',
              onTap: () => _sendEmail('support@yumyum.ru'),
              onLongPress: () => _copyToClipboard('support@yumyum.ru', 'Email'),
            ),

            // Время работы (Статично)
            _buildContactItem(
              icon: Icons.access_time,
              title: 'Время работы',
              subtitle: 'Круглосуточно, 24/7',
            ),

            // Чат (Заглушка)
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
    VoidCallback? onLongPress,
  }) {
    return InkWell( // Добавил InkWell для обработки нажатий и Ripple эффекта
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0), // Увеличил зону нажатия
        child: Row(
          children: [
            Icon(icon, color: Colors.orange),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            if (onTap != null) // Показываем иконку только если элемент кликабелен
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
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
}