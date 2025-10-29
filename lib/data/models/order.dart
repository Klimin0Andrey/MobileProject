import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linux_test2/data/models/cart_item.dart';
import 'package:linux_test2/data/models/dish.dart';


enum OrderStatus { pending, processing, delivering, completed, cancelled }

class Order {
  final String? id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final OrderStatus status;
  final String address;
  final Timestamp createdAt;
  final String? courierId;

  final String phone;
  final String paymentMethod;
  final String? comment;

  Order({
    this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    this.status = OrderStatus.pending,
    required this.address,
    required this.createdAt,
    this.courierId,
    // --- ДОБАВЛЯЕМ В КОНСТРУКТОР ---
    required this.phone,
    required this.paymentMethod,
    this.comment,
  });

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
              'imageUrl': item.dish.imageUrl, // Добавьте это поле
            },
          )
          .toList(),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'address': address,
      'createdAt': createdAt,
      'courierId': courierId,
      // --- СОХРАНЯЕМ НОВЫЕ ПОЛЯ В FIRESTORE ---
      'phone': phone,
      'paymentMethod': paymentMethod,
      'comment': comment,
    };
  }

  static Order fromMap(Map<String, dynamic> map, String documentId) {
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
              category: item['category'] ?? 'main', // Добавьте это
              description: item['description'] ?? '', // Добавьте это
              isAvailable: item['isAvailable'] ?? true, // Добавьте это
              restaurantId: item['restaurantId'] ?? '', // Добавьте это
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
      address: map['address'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      courierId: map['courierId'],
      // ДОБАВЛЯЕМ ЧТЕНИЕ НОВЫХ ПОЛЕЙ ИЗ FIRESTORE
      phone: map['phone'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      comment: map['comment'],
    );
  }
}
