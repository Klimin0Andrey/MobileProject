import 'package:flutter/material.dart';

class CourierHome extends StatelessWidget {
  const CourierHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доставка еды - Курьер'),
      ),
      body: const Center(
        child: Text('Главная страница для курьеров'),
      ),
    );
  }
}