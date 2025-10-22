import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class GuestHome extends StatelessWidget {
  const GuestHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Доставка еды',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/dots.svg',
              height: 5,
              width: 5,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSearchField(),
          const SizedBox(height: 30),
          _buildCategoriesSection(),
          const SizedBox(height: 30),
          _buildRestaurantsSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1D1617).withValues(alpha: 0.11),
            blurRadius: 40,
            spreadRadius: 0.0,
          )
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(15),
          hintText: 'Поиск ресторанов или блюд...',
          hintStyle: const TextStyle(
            color: Color(0xffDDDADA),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset('assets/icons/Search.svg'),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Категории',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 20),
            children: [
              _buildCategoryItem('Пицца', 'assets/icons/pizza.svg'),
              _buildCategoryItem('Суши', 'assets/icons/sushi.svg'),
              _buildCategoryItem('Бургеры', 'assets/icons/burger.svg'),
              _buildCategoryItem('Азиатская', 'assets/icons/asian.svg'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String name, String iconPath) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: const Color(0xff9DCEFF).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(iconPath),
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Популярные рестораны',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 20),
            children: [
              _buildRestaurantCard(),
              _buildRestaurantCard(),
              _buildRestaurantCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantCard() {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: const Color(0xff9DCEFF).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Название ресторана',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '30-40 мин • ★ 4.5',
            style: TextStyle(
              color: Color(0xff7B6F72),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: Colors.grey.shade600),
          activeIcon: const Icon(Icons.home, color: Color(0xFF2C3E50)),
          label: 'Главная',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart, color: Colors.grey.shade600),
          activeIcon: const Icon(Icons.shopping_cart, color: Color(0xFF2C3E50)),
          label: 'Корзина',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, color: Colors.grey.shade600),
          activeIcon: const Icon(Icons.person, color: Color(0xFF2C3E50)),
          label: 'Профиль',
        ),
      ],
      currentIndex: 0,
      onTap: (index) {
        if (index == 1 || index == 2) {
          // Показываем модалку авторизации при попытке доступа к корзине/профилю
          _showAuthModal(context);
        }
      },
    );
  }

  void _showAuthModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется авторизация'),
        content: const Text('Войдите или зарегистрируйтесь для доступа к этой функции'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Переход на экран авторизации
              Navigator.pushNamed(context, '/auth');
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
}