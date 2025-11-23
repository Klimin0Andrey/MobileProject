import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/restaurant.dart';
import 'package:linux_test2/data/models/dish.dart';
import 'package:linux_test2/presentation/providers/admin_menu_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linux_test2/presentation/widgets/universal_image.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление меню'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateRestaurantDialog(context),
            tooltip: 'Добавить ресторан',
          ),
        ],
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: Provider.of<AdminMenuProvider>(context).getAllRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final restaurants = snapshot.data ?? [];

          if (restaurants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Нет ресторанов',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateRestaurantDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить ресторан'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              return _buildRestaurantCard(context, restaurants[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _openRestaurantDetails(context, restaurant),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Изображение ресторана
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: restaurant.imageUrl.isNotEmpty
                    ? UniversalImage(
                        imageUrl:restaurant.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.restaurant),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.restaurant),
                      ),
              ),
              const SizedBox(width: 12),
              // Информация о ресторане
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!restaurant.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Неактивен',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.deliveryTime,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: restaurant.cuisineType.take(3).map((cuisine) {
                        return Chip(
                          label: Text(
                            cuisine,
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              // Кнопки действий
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: restaurant.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          restaurant.isActive ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(restaurant.isActive ? 'Деактивировать' : 'Активировать'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditRestaurantDialog(context, restaurant);
                  } else if (value == 'deactivate') {
                    _deactivateRestaurant(context, restaurant);
                  } else if (value == 'activate') {
                    _activateRestaurant(context, restaurant);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRestaurantDetails(BuildContext context, Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantDishesScreen(restaurant: restaurant),
      ),
    );
  }

  Future<void> _showCreateRestaurantDialog(BuildContext context) async {
    // Диалог создания ресторана
    // (Упрощенная версия, можно расширить)
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final deliveryTimeController = TextEditingController();
    final cuisineController = TextEditingController();
    String? imageUrl;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать ресторан'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deliveryTimeController,
                decoration: const InputDecoration(
                  labelText: 'Время доставки (например: 30-40 мин)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cuisineController,
                decoration: const InputDecoration(
                  labelText: 'Тип кухни (через запятую)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  deliveryTimeController.text.isNotEmpty &&
                  cuisineController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (result == true) {
      final cuisineTypes = cuisineController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      try {
        await Provider.of<AdminMenuProvider>(context, listen: false)
            .createRestaurant(
          name: nameController.text,
          description: descriptionController.text,
          deliveryTime: deliveryTimeController.text,
          cuisineType: cuisineTypes,
          imageUrl: imageUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ресторан создан')),
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

  Future<void> _showEditRestaurantDialog(BuildContext context, Restaurant restaurant) async {
    // Аналогично созданию, но с предзаполненными полями
    // (Упрощенная версия)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование ресторана (в разработке)')),
    );
  }

  Future<void> _deactivateRestaurant(BuildContext context, Restaurant restaurant) async {
    try {
      await Provider.of<AdminMenuProvider>(context, listen: false)
          .updateRestaurant(
        restaurantId: restaurant.id,
        isActive: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ресторан деактивирован')),
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

  Future<void> _activateRestaurant(BuildContext context, Restaurant restaurant) async {
    try {
      await Provider.of<AdminMenuProvider>(context, listen: false)
          .updateRestaurant(
        restaurantId: restaurant.id,
        isActive: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ресторан активирован')),
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

// Экран блюд ресторана
class RestaurantDishesScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDishesScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDishesScreen> createState() => _RestaurantDishesScreenState();
}

class _RestaurantDishesScreenState extends State<RestaurantDishesScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDishDialog(context),
            tooltip: 'Добавить блюдо',
          ),
        ],
      ),
      body: StreamBuilder<List<Dish>>(
        stream: Provider.of<AdminMenuProvider>(context)
            .getRestaurantDishes(widget.restaurant.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final dishes = snapshot.data ?? [];

          if (dishes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Нет блюд',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDishDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить блюдо'),
                  ),
                ],
              ),
            );
          }

          // Группируем блюда по категориям
          final dishesByCategory = <String, List<Dish>>{};
          for (var dish in dishes) {
            dishesByCategory.putIfAbsent(dish.category, () => []).add(dish);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: dishesByCategory.length,
            itemBuilder: (context, index) {
              final category = dishesByCategory.keys.elementAt(index);
              final categoryDishes = dishesByCategory[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...categoryDishes.map((dish) => _buildDishCard(context, dish)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDishCard(BuildContext context, Dish dish) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: dish.isAvailable ? null : Colors.grey.shade200,
      child: ListTile(
        leading: dish.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: UniversalImage(
                  imageUrl: dish.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.fastfood),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade300,
                child: const Icon(Icons.fastfood),
              ),
        title: Text(
          dish.name,
          style: TextStyle(
            decoration: dish.isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dish.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${dish.price.toStringAsFixed(2)} ₽',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: dish.isAvailable,
              onChanged: (value) => _toggleDishAvailability(context, dish, value),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Редактировать'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Удалить', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDishDialog(context, dish);
                } else if (value == 'delete') {
                  _deleteDish(context, dish);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDishDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить блюдо'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  categoryController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final price = double.tryParse(priceController.text);
        if (price == null || price <= 0) {
          throw Exception('Некорректная цена');
        }

        await Provider.of<AdminMenuProvider>(context, listen: false).createDish(
          restaurantId: widget.restaurant.id,
          name: nameController.text,
          description: descriptionController.text,
          price: price,
          category: categoryController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Блюдо добавлено')),
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

  Future<void> _toggleDishAvailability(BuildContext context, Dish dish, bool isAvailable) async {
    try {
      await Provider.of<AdminMenuProvider>(context, listen: false)
          .toggleDishAvailability(dish.id, isAvailable);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAvailable ? 'Блюдо доступно' : 'Блюдо недоступно'),
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

  Future<void> _showEditDishDialog(BuildContext context, Dish dish) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование блюда (в разработке)')),
    );
  }

  Future<void> _deleteDish(BuildContext context, Dish dish) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить блюдо?'),
        content: Text('Вы уверены, что хотите удалить "${dish.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<AdminMenuProvider>(context, listen: false)
            .updateDish(dishId: dish.id, isAvailable: false); // Или удалить полностью

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Блюдо удалено')),
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
}
