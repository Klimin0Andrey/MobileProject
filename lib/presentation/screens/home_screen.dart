import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/user.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/presentation/providers/restaurant_provider.dart';
import 'package:linux_test2/presentation/providers/cart_provider.dart';
import 'package:linux_test2/presentation/providers/address_provider.dart';
import 'package:linux_test2/presentation/widgets/restaurant_card.dart';
import 'package:linux_test2/presentation/screens/customer/cart_screen.dart';
import 'package:linux_test2/presentation/screens/auth/authenticate.dart';
import 'package:linux_test2/presentation/screens/customer/profile_screen.dart';
import 'package:linux_test2/presentation/screens/checkout/address_selection_screen.dart';
import 'package:linux_test2/presentation/screens/customer/notifications_screen.dart';
import 'package:linux_test2/presentation/widgets/universal_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> cuisineTypes = [
    'Все',
    'Итальянская',
    'Азиатская',
    'Фастфуд',
    'Десерты',
  ];
  int _currentTabIndex = 0;

  // ImageProvider _getAvatarImage(String? avatarUrl) {
  //   if (avatarUrl == null || avatarUrl.isEmpty) {
  //     return const NetworkImage(''); // Пустая ссылка для иконки по умолчанию
  //   }
  //   if (avatarUrl.startsWith('data:image')) {
  //     return MemoryImage(base64Decode(avatarUrl.split(',').last));
  //   }
  //   return NetworkImage(avatarUrl);
  // }

  Future<void> _changeAddress() async {
    final selected = await Navigator.push<DeliveryAddress>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressSelectionScreen(),
      ),
    );

    if (selected != null && mounted) {
      context.read<AddressProvider>().setSelectedAddress(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    final isGuest = user == null;

    return Scaffold(
      // Используем SafeArea, чтобы контент не залезал на "челку" телефона
      body: SafeArea(
        child: _buildBody(context, user, isGuest),
      ),
      bottomNavigationBar: isGuest ? null : _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody(BuildContext context, AppUser? user, bool isGuest) {
    if (_currentTabIndex == 1 && !isGuest) {
      return const CartScreen();
    }

    if (_currentTabIndex == 2 && !isGuest) {
      return const ProfileScreen();
    }

    return ChangeNotifierProvider(
      create: (context) => RestaurantProvider(),
      child: Consumer<RestaurantProvider>(
        builder: (context, restaurantProvider, child) {
          return Column(
            children: [
              // ✅ ОБНОВЛЕННАЯ ШАПКА
              _buildCustomHeader(context, user, isGuest),

              // Поиск
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск ресторанов...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    // Подстраиваем цвет под тему (светлая/темная)
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    restaurantProvider.searchRestaurants(value);
                  },
                ),
              ),

              // Баннер для гостей
              if (isGuest) _buildGuestBanner(context),

              // Фильтры по кухне
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cuisineTypes.length,
                  itemBuilder: (context, index) {
                    final cuisine = cuisineTypes[index];
                    final isSelected = restaurantProvider.selectedCuisine == cuisine;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        label: Text(cuisine),
                        selected: isSelected,
                        onSelected: (selected) {
                          restaurantProvider.filterByCuisine(cuisine);
                        },
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        selectedColor: Colors.orange.withOpacity(0.2),
                        checkmarkColor: Colors.orange,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.orange : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ✅ ДОБАВЛЕНО: Фильтр по рейтингу
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Рейтинг от:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          // Фильтры-чипы для рейтинга
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildRatingChip(context, restaurantProvider, 0.0, 'Все'),
                                  const SizedBox(width: 8),
                                  _buildRatingChip(context, restaurantProvider, 4.0, '4.0+'),
                                  const SizedBox(width: 8),
                                  _buildRatingChip(context, restaurantProvider, 4.5, '4.5+'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ ДОБАВЛЕНО: Сортировка
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.sort, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Сортировка:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortChip(
                              context,
                              restaurantProvider,
                              SortType.none,
                              'По умолчанию',
                            ),
                            const SizedBox(width: 8),
                            _buildSortChip(
                              context,
                              restaurantProvider,
                              SortType.ratingDesc,
                              '⭐ Рейтинг',
                            ),
                            const SizedBox(width: 8),
                            _buildSortChip(
                              context,
                              restaurantProvider,
                              SortType.deliveryTime,
                              '⏱ Время',
                            ),
                            const SizedBox(width: 8),
                            _buildSortChip(
                              context,
                              restaurantProvider,
                              SortType.nameAsc,
                              'А-Я',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Количество
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Найдено ресторанов: ${restaurantProvider.restaurants.length}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Spacer(),
                    // ✅ ДОБАВЛЕНО: Кнопка сброса фильтров
                    if (restaurantProvider.selectedCuisine != 'Все' ||
                        restaurantProvider.minRating > 0.0 ||
                        restaurantProvider.sortType != SortType.none)
                      TextButton.icon(
                        onPressed: () {
                          restaurantProvider.resetFilters();
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Сбросить', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Список
              Expanded(
                child: RefreshIndicator(
                  color: Colors.orange,
                  onRefresh: () async {
                    // restaurantProvider.refresh();
                  },
                  child: restaurantProvider.restaurants.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Рестораны не найдены', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        if (!isGuest && Provider.of<AddressProvider>(context).selectedAddress == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: TextButton(
                              onPressed: _changeAddress,
                              child: const Text('Указать адрес', style: TextStyle(color: Colors.orange)),
                            ),
                          )
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
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
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ ВОТ ЗДЕСЬ ГЛАВНЫЕ ИЗМЕНЕНИЯ В ДИЗАЙНЕ ШАПКИ
  Widget _buildCustomHeader(BuildContext context, AppUser? user, bool isGuest) {
    final addressProvider = isGuest ? null : Provider.of<AddressProvider>(context);
    final currentAddress = addressProvider?.selectedAddress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Аватарка
          GestureDetector(
            onTap: () {
              if (isGuest) {
                _showLoginDialog(context);
              } else {
                setState(() => _currentTabIndex = 2); // Переход в профиль
              }
            },
            child: CircleAvatar(
              radius: 22, // Чуть больше
              backgroundColor: Colors.orange.shade100,
              // backgroundImage убираем, всё переносим в child
              child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                  ? ClipOval(
                child: UniversalImage(
                  imageUrl: user.avatarUrl!,
                  width: 44, // radius * 2
                  height: 44,
                  fit: BoxFit.cover,
                  // Если картинка битая или не грузится — показываем твою иконку
                  errorWidget: const Center(
                    child: Icon(Icons.person, color: Colors.orange),
                  ),
                ),
              )
              // Если ссылки нет — показываем твою иконку
                  : const Icon(Icons.person, color: Colors.orange),
            ),
          ),

          const SizedBox(width: 12),

          // Адрес (Центральная часть)
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isGuest) {
                  _showLoginDialog(context);
                } else {
                  _changeAddress();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Строка 1: Название адреса + Стрелочка
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          currentAddress?.title ?? 'Укажите адрес',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // Цвет текста адаптируется под тему
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.orange, size: 20),
                    ],
                  ),

                  // Строка 2: Сам адрес (улица, дом)
                  if (currentAddress != null && currentAddress.address.isNotEmpty)
                    Text(
                      currentAddress.address,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600] // Серый цвет для второстепенного текста
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Троеточие, если длинный
                    ),
                ],
              ),
            ),
          ),

          // Колокольчик
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                // ✅ ПЕРЕХОД НА ЭКРАН УВЕДОМЛЕНИЙ
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Войдите, чтобы делать заказы',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => _showLoginDialog(context),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return BottomNavigationBar(
          currentIndex: _currentTabIndex,
          selectedItemColor: Colors.orange, // Оранжевый для активной вкладки
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Рестораны',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  if (cartProvider.totalItems > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          cartProvider.totalItems > 99 ? '99+' : cartProvider.totalItems.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.shopping_cart),
              label: 'Корзина',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Профиль',
            ),
          ],
        );
      },
    );
  }

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

  // ✅ ДОБАВЛЕНО: Вспомогательный метод для чипа рейтинга
  Widget _buildRatingChip(
    BuildContext context,
    RestaurantProvider provider,
    double rating,
    String label,
  ) {
    final isSelected = provider.minRating == rating;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rating > 0) ...[
            const Icon(Icons.star, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        provider.filterByRating(rating);
      },
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[100],
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // ✅ ДОБАВЛЕНО: Вспомогательный метод для чипа сортировки
  Widget _buildSortChip(
    BuildContext context,
    RestaurantProvider provider,
    SortType sortType,
    String label,
  ) {
    final isSelected = provider.sortType == sortType;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        provider.sortRestaurants(sortType);
      },
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[100],
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}