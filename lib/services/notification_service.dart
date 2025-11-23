import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:linux_test2/data/models/support_ticket.dart';
import 'package:flutter/material.dart' show debugPrint;


// ✅ ДОБАВЛЕНО: Глобальный обработчик для фоновых уведомлений
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Фоновое уведомление: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ ДОБАВЛЕНО: Локальные уведомления
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // ✅ ДОБАВЛЕНО: Stream для отслеживания статуса заказов
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  
  // ✅ ДОБАВЛЕНО: Stream для отслеживания тикетов поддержки
  StreamSubscription<QuerySnapshot>? _supportTicketsSubscription;

  // Инициализация уведомлений
  Future<void> initNotifications() async {
    // 1. Инициализация локальных уведомлений
    await _initLocalNotifications();
    
    // 2. Настройка фонового обработчика
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // 3. Запрос разрешений
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Уведомления разрешены');

      // 4. Проверяем токен при старте
      await saveTokenToDatabase();

      // 5. Слушаем обновление токена
      _fcm.onTokenRefresh.listen((newToken) {
        saveTokenToDatabase(token: newToken);
      });

      // 6. ✅ УЛУЧШЕНО: Обработка уведомлений, когда приложение ОТКРЫТО
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Получено сообщение (FOREGROUND): ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // 7. ✅ ДОБАВЛЕНО: Обработка нажатий на уведомления (когда приложение в фоне)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔔 Уведомление открыто из фона: ${message.notification?.title}');
        _handleNotificationTap(message);
      });

      // 8. ✅ ДОБАВЛЕНО: Проверка, было ли приложение открыто из уведомления
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // 9. ✅ ДОБАВЛЕНО: Начинаем отслеживать изменения статуса заказов
      _startOrderStatusListener();

      // 9. ✅ ДОБАВЛЕНО: Начинаем отслеживать ответы поддержки
      _startSupportTicketsListener();
    } else {
      print('❌ Пользователь запретил уведомления');
    }
  }

  // ✅ ДОБАВЛЕНО: Инициализация локальных уведомлений
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          // Проверяем, это уведомление о тикете или заказе
          if (response.payload!.startsWith('support_ticket:')) {
            final ticketId = response.payload!.split(':')[1];
            print('💬 Открываем тикет поддержки: $ticketId');
            // TODO: Навигация на экран тикета (нужен BuildContext)
          } else {
            // Обработка уведомлений о заказах
            print('�� Нажато на локальное уведомление: ${response.payload}');
          }
        }
      },
    );

    // Создаем канал для Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Уведомления о заказах',
      description: 'Уведомления об изменении статуса заказов',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ✅ ДОБАВЛЕНО: Показ локального уведомления
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Уведомления о заказах',
      channelDescription: 'Уведомления об изменении статуса заказов',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Новое уведомление',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  // ✅ ДОБАВЛЕНО: Обработка нажатия на уведомление
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (data != null) {
      // Обработка уведомлений о заказах
      if (data.containsKey('orderId')) {
        final orderId = data['orderId'] as String?;
        if (orderId != null) {
          print('�� Открываем заказ: $orderId');
          // TODO: Навигация на экран заказа
        }
      }
      
      // ✅ ДОБАВЛЕНО: Обработка уведомлений о тикетах поддержки
      // (будет использоваться при нажатии на локальные уведомления)
    }
  }

  // ✅ ДОБАВЛЕНО: Отслеживание изменений статуса заказов
  void _startOrderStatusListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Отслеживаем заказы текущего пользователя
    _ordersSubscription = _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final oldData = change.doc.metadata.hasPendingWrites
              ? null
              : change.doc.data();
          final newData = change.doc.data();

          // ✅ ИСПРАВЛЕНО: Проверяем, изменился ли статус с правильными проверками на null
          if (oldData != null && 
              newData != null &&
              oldData.containsKey('status') &&
              newData.containsKey('status') &&
              oldData['status'] != newData['status']) {
            final orderId = change.doc.id;
            final oldStatus = oldData['status'] as String? ?? '';
            final newStatus = newData['status'] as String? ?? '';

            // Показываем локальное уведомление об изменении статуса
            _showOrderStatusNotification(
              orderId: orderId,
              oldStatus: oldStatus,
              newStatus: newStatus,
            );
          }
        }
      }
    });
  }

  // ✅ ДОБАВЛЕНО: Показ уведомления об изменении статуса заказа
  Future<void> _showOrderStatusNotification({
    required String orderId,
    required String oldStatus,
    required String newStatus,
  }) async {
    String title = 'Статус заказа изменен';
    String body = _getStatusMessage(newStatus);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Уведомления о заказах',
      channelDescription: 'Уведомления об изменении статуса заказов',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      orderId.hashCode,
      title,
      body,
      details,
      payload: orderId, // Передаем ID заказа для навигации
    );
  }

  // ✅ ДОБАВЛЕНО: Получение сообщения для статуса
  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Ваш заказ ожидает подтверждения';
      case 'processing':
        return 'Ваш заказ готовится';
      case 'delivering':
        return 'Ваш заказ в пути';
      case 'completed':
        return 'Ваш заказ доставлен. Приятного аппетита!';
      case 'cancelled':
        return 'Ваш заказ отменен';
      default:
        return 'Статус заказа изменен';
    }
  }

  // ✅ ДОБАВЛЕНО: Отслеживание ответов поддержки
  void _startSupportTicketsListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Отслеживаем тикеты текущего пользователя
    _supportTicketsSubscription = _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final oldData = change.doc.metadata.hasPendingWrites
              ? null
              : change.doc.data();
          final newData = change.doc.data();

          // Проверяем, появился ли новый ответ от поддержки
          if (oldData != null && 
              newData != null &&
              oldData.containsKey('adminReply') &&
              newData.containsKey('adminReply')) {
            
            final oldReply = oldData['adminReply'] as String?;
            final newReply = newData['adminReply'] as String?;
            
            // Если ответ изменился с null/пустого на непустой
            if ((oldReply == null || oldReply.isEmpty) && 
                newReply != null && 
                newReply.isNotEmpty) {
              final ticketId = change.doc.id;
              final subject = newData['subject'] as String? ?? 'Ваше обращение';
              
              // Показываем уведомление о новом ответе
              _showSupportReplyNotification(
                ticketId: ticketId,
                subject: subject,
              );
            }
          }
        }
      }
    });
  }

  // ✅ ДОБАВЛЕНО: Показ уведомления о новом ответе поддержки
  Future<void> _showSupportReplyNotification({
    required String ticketId,
    required String subject,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Уведомления о заказах',
      channelDescription: 'Уведомления об изменении статуса заказов',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      ticketId.hashCode + 10000, // Добавляем смещение, чтобы не конфликтовало с заказами
      'Новый ответ от поддержки',
      'По вашему обращению "$subject" получен ответ',
      details,
      payload: 'support_ticket:$ticketId', // Передаем ID тикета для навигации
    );
  }

  // ✅ ДОБАВЛЕНО: Остановка отслеживания заказов
  void stopOrderStatusListener() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
  }

  // ✅ ДОБАВЛЕНО: Остановка отслеживания тикетов
  void stopSupportTicketsListener() {
    _supportTicketsSubscription?.cancel();
    _supportTicketsSubscription = null;
  }

  // Сохранение токена в БД
  Future<void> saveTokenToDatabase({String? token}) async {
    User? user = _auth.currentUser;

    if (user == null) return;

    String? fcmToken = token ?? await _fcm.getToken();

    if (fcmToken != null) {
      print('📲 Сохраняем FCM Token для ${user.email}: $fcmToken');

      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': fcmToken,
          'platform': Platform.operatingSystem,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Токен успешно записан в Firestore');
      } catch (e) {
        print('❌ Ошибка записи токена в БД: $e');
      }
    }
  }

  void subscribeToTopic(String topic) {
    _fcm.subscribeToTopic(topic);
  }

  void unsubscribeFromTopic(String topic) {
    _fcm.unsubscribeFromTopic(topic);
  }

  // ✅ ДОБАВЛЕНО: Очистка ресурсов
  void dispose() {
    stopOrderStatusListener();
    stopSupportTicketsListener(); // ✅ ДОБАВЛЕНО
  }

  // ✅ ДОБАВЛЕНО: Отправка уведомления о статусе заказа
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String title,
    required String body,
    required String orderId,
  }) async {
    try {
      // Получаем токен пользователя из Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('❌ Пользователь $userId не найден');
        return;
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('❌ У пользователя $userId нет FCM токена');
        return;
      }

      // Отправляем уведомление через Firebase Cloud Messaging
      // Примечание: Для реальной отправки нужен сервер или Cloud Functions
      // Здесь мы только логируем, но можно использовать HTTP API
      debugPrint('📤 Отправка уведомления пользователю $userId: $title');
      
      // Показываем локальное уведомление (для тестирования)
      await _localNotifications.show(
        orderId.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'order_status_channel',
            'Статусы заказов',
            channelDescription: 'Уведомления об изменении статуса заказа',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Ошибка при отправке уведомления: $e');
    }
  }
}