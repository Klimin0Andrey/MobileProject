class Restaurant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final String deliveryTime;
  final List<String> cuisineType;
  final bool isActive;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTime,
    required this.cuisineType,
    required this.isActive,
  });
}