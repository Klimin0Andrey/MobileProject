import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/presentation/providers/address_provider.dart';
import 'package:linux_test2/presentation/screens/customer/add_edit_address_screen.dart';

class AddressSelectionScreen extends StatelessWidget {
  const AddressSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите адрес доставки'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AddressProvider>(
        builder: (context, addressProvider, child) {
          final addresses = addressProvider.addresses;

          if (addresses.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];

                    // Проверяем, выбран ли этот адрес сейчас (сравниваем по ID)
                    final isSelected = address.id == addressProvider.selectedAddress?.id;

                    return Card(
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        // Подсвечиваем выбранный адрес рамкой
                        side: isSelected
                            ? const BorderSide(color: Colors.orange, width: 2)
                            : BorderSide.none,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          // ✅ ГЛАВНОЕ: Возвращаем выбранный адрес
                          Navigator.of(context).pop(address);
                        },
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.orange : Colors.grey[200],
                          child: Icon(
                            _getAddressIcon(address.title),
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                        title: Text(
                          address.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected ? Colors.orange[800] : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          address.fullAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Кнопка редактирования справа
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddEditAddressScreen(addressId: address.id),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Кнопка "Добавить" внизу
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddEditAddressScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Добавить новый адрес'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Нет сохраненных адресов',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Добавьте адрес для доставки заказа',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddEditAddressScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить первый адрес'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressIcon(String title) {
    switch (title.toLowerCase()) {
      case 'дом': return Icons.home;
      case 'работа': return Icons.work;
      default: return Icons.location_on;
    }
  }
}