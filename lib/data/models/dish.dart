class Dish {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String restaurantId;
  final bool isAvailable;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.restaurantId,
    required this.isAvailable,
  });

  // ✅ ДОБАВЛЕНО: Метод для создания объекта из данных БД
  factory Dish.fromMap(Map<String, dynamic> map, String documentId) {
    return Dish(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      // Безопасное приведение числа (вдруг в БД записан int)
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  // ✅ ДОБАВЛЕНО: Метод для отправки данных в БД (понадобится для админки)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'restaurantId': restaurantId,
      'isAvailable': isAvailable,
    };
  }

}