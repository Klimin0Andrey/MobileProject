import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/services/auth.dart';
import 'package:linux_test2/presentation/providers/restaurant_provider.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/widgets/restaurant_card.dart';
import 'package:linux_test2/presentation/screens/customer/cart_screen.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> cuisineTypes = ['Все', 'Итальянская', 'Азиатская', 'Фастфуд', 'Десерты'];
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    final isGuest = user == null;

    return Scaffold(
      appBar: _buildAppBar(context, isGuest),
      body: _buildBody(isGuest),
      bottomNavigationBar: isGuest ? null : _buildBottomNavigationBar(),
      floatingActionButton: isGuest ? _buildGuestFAB(context) : _buildCartFAB(context),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isGuest) {
    return AppBar(
      title: const Text('Рестораны и кафе'),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      actions: [
        if (isGuest)
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () {
              _showLoginDialog(context);
            },
          )
        else
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
      ],
    );
  }

  Widget _buildBody(bool isGuest) {
    if (_currentTabIndex == 1 && !isGuest) {
      return const CartScreen(); // Вкладка корзины
    }

    if (_currentTabIndex == 2 && !isGuest) {
      return _buildProfileTab(); // Вкладка профиля
    }

    // Главная вкладка (рестораны) - для всех
    return ChangeNotifierProvider(
      create: (context) => RestaurantProvider(),
      child: Consumer<RestaurantProvider>(
        builder: (context, restaurantProvider, child) {
          return Column(
            children: [
              // Баннер для гостей
              if (isGuest)
                _buildGuestBanner(context),

              // Поиск
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск ресторанов...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    restaurantProvider.searchRestaurants(value);
                  },
                ),
              ),

              // Фильтры по кухне
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cuisineTypes.length,
                  itemBuilder: (context, index) {
                    final cuisine = cuisineTypes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        label: Text(cuisine),
                        selected: restaurantProvider.selectedCuisine == cuisine,
                        onSelected: (selected) {
                          restaurantProvider.filterByCuisine(cuisine);
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Количество найденных ресторанов
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Найдено ресторанов: ${restaurantProvider.restaurants.length}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Список ресторанов
              Expanded(
                child: restaurantProvider.restaurants.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Рестораны не найдены',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: restaurantProvider.restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurantProvider.restaurants[index];
                    return RestaurantCard(
                      restaurant: restaurant,
                      isGuest: isGuest,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Войдите, чтобы добавлять в корзину и оформлять заказы',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () {
              _showLoginDialog(context);
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Профиль пользователя',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text('Здесь будет личный кабинет'),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) {
        setState(() {
          _currentTabIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Рестораны',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Корзина',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ],
    );
  }

  // ОБНОВЛЕННЫЙ МЕТОД ДЛЯ ГОСТЕЙ
  Widget _buildGuestFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Authenticate()),
        );
      },
      backgroundColor: Colors.orange,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 20),
          Text('Войти', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // СУЩЕСТВУЮЩИЙ МЕТОД ДЛЯ КОРЗИНЫ (для авторизованных пользователей)
  Widget _buildCartFAB(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (_currentTabIndex == 1) return const SizedBox(); // Не показывать FAB на вкладке корзины

        return FloatingActionButton(
          onPressed: () {
            setState(() {
              _currentTabIndex = 1; // Переключаем на вкладку корзины
            });
          },
          backgroundColor: Colors.orange,
          child: Stack(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              if (cartProvider.totalItems > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartProvider.totalItems.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ОБНОВЛЕННЫЙ МЕТОД ДЛЯ ДИАЛОГА ВХОДА
  void _showLoginDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Authenticate()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}