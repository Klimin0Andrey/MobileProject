import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/cart_item.dart';
import 'package:linux_test2/data/models/dish.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:latlong2/latlong.dart';

enum OrderStatus { pending, processing, delivering, completed, cancelled }

class Order {
  final String? id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final OrderStatus status;
  final DeliveryAddress deliveryAddress; // ✅ ИЗМЕНЕНО: DeliveryAddress вместо String
  final String deliveryAddressString; // ✅ ДОБАВЛЕНО: для отображения
  final Timestamp createdAt;
  final String? courierId;
  final String phone;
  final String paymentMethod;
  final String? comment;
  final Map<String, dynamic>? courierLocation;

  Order({
    this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    this.status = OrderStatus.pending,
    required this.deliveryAddress,
    required this.createdAt,
    this.courierId,
    required this.phone,
    required this.paymentMethod,
    this.comment,
    this.courierLocation,
  }) : deliveryAddressString = deliveryAddress.fullAddress;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items
          .map(
            (item) => {
              'dishId': item.dish.id,
              'dishName': item.dish.name,
              'quantity': item.quantity,
              'price': item.dish.price,
              'imageUrl': item.dish.imageUrl,
            },
          )
          .toList(),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'deliveryAddress': deliveryAddress.toMap(),
      'deliveryAddressString': deliveryAddressString,
      'createdAt': createdAt,
      'courierId': courierId,
      'phone': phone,
      'paymentMethod': paymentMethod,
      'comment': comment,
    };
  }

  static Order fromMap(Map<String, dynamic> map, String documentId) {
    // ✅ ИЗМЕНЕНО: обработка адреса с обратной совместимостью
    DeliveryAddress address;
    if (map['deliveryAddress'] != null) {
      // Новый формат: объект адреса
      final addressMap = Map<String, dynamic>.from(map['deliveryAddress']);
      address = DeliveryAddress.fromMap(addressMap);
    } else {
      // Старый формат: строка адреса (для обратной совместимости)
      address = DeliveryAddress(
        id: 'legacy_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Адрес доставки',
        address: map['address'] ?? '',
        // старый формат
        isDefault: false,
        createdAt: DateTime.now(),
      );
    }

    return Order(
      id: documentId,
      userId: map['userId'] ?? '',
      items: List<CartItem>.from(
        (map['items'] as List).map(
          (item) => CartItem(
            dish: Dish(
              id: item['dishId'] ?? '',
              name: item['dishName'] ?? '',
              price: (item['price'] as num).toDouble(),
              imageUrl: item['imageUrl'] ?? '',
              category: item['category'] ?? 'main',
              description: item['description'] ?? '',
              isAvailable: item['isAvailable'] ?? true,
              restaurantId: item['restaurantId'] ?? '',
            ),
            quantity: item['quantity'] ?? 1,
          ),
        ),
      ),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      deliveryAddress: address,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      courierId: map['courierId'],
      phone: map['phone'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      comment: map['comment'],
      courierLocation: map['courierLocation'] != null
          ? Map<String, dynamic>.from(map['courierLocation'])
          : null,
    );
  }

  // ✅ ДОБАВЛЕНО: Вспомогательные методы для работы с позицией курьера
  LatLng? get courierPosition {
    if (courierLocation == null) return null;
    final lat = courierLocation!['latitude'] as num?;
    final lng = courierLocation!['longitude'] as num?;
    if (lat != null && lng != null) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  // ✅ ДОПОЛНИТЕЛЬНЫЙ МЕТОД: для получения строки адреса
  String get formattedAddress {
    return deliveryAddress.fullAddress;
  }

  // ✅ ДОПОЛНИТЕЛЬНЫЙ МЕТОД: для получения названия адреса
  String get addressTitle {
    return deliveryAddress.title;
  }
}
