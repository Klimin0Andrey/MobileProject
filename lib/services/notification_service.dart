import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


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
  
  // ✅ ДОБАВЛЕНО: Stream для отслеживания изменений статуса заказов
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

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
        // Обработка нажатия на локальное уведомление
        print('🔔 Нажато на локальное уведомление: ${response.payload}');
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
    // Здесь можно добавить навигацию на нужный экран
    // Например, если в data есть orderId, открыть экран заказа
    final data = message.data;
    if (data != null && data.containsKey('orderId')) {
      final orderId = data['orderId'] as String?;
      if (orderId != null) {
        // TODO: Навигация на экран заказа
        print('📦 Открываем заказ: $orderId');
      }
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

  // ✅ ДОБАВЛЕНО: Остановка отслеживания заказов
  void stopOrderStatusListener() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
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
  }
}