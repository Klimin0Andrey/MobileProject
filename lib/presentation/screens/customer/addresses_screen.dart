import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/presentation/providers/address_provider.dart';
import 'package:linux_test2/presentation/screens/customer/add_edit_address_screen.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои адреса'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AddressProvider>(
        builder: (context, addressProvider, child) {
          final addresses = addressProvider.addresses;

          if (addresses.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(context, address, addressProvider);
            },
          );
        },
      ),
      // ✅ FAB показывается ТОЛЬКО когда есть адреса
      floatingActionButton: Consumer<AddressProvider>(
        builder: (context, addressProvider, child) {
          if (addressProvider.addresses.isEmpty) {
            return const SizedBox.shrink(); // Скрываем FAB
          }
          return FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddEditAddressScreen(),
                ),
              );
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add, color: Colors.white),
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
            const Icon(Icons.location_on_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Нет сохраненных адресов',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Добавьте адрес для быстрого оформления заказов',
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
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Добавить первый адрес'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... остальные методы без изменений
  Widget _buildAddressCard(
      BuildContext context,
      DeliveryAddress address,
      AddressProvider addressProvider,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getAddressIcon(address.title),
          color: Colors.orange,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  address.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'По умолчанию',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              address.fullAddress,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (address.comment != null && address.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Комментарий: ${address.comment}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handlePopupMenuSelection(
            value, address.id, context, addressProvider,
          ),
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
            if (!address.isDefault) const PopupMenuItem(
              value: 'set_default',
              child: Row(
                children: [
                  Icon(Icons.star, size: 20),
                  SizedBox(width: 8),
                  Text('Сделать основным'),
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
        ),
      ),
    );
  }

  IconData _getAddressIcon(String title) {
    switch (title.toLowerCase()) {
      case 'дом':
        return Icons.home;
      case 'работа':
        return Icons.work;
      case 'квартира':
        return Icons.apartment;
      case 'родители':
        return Icons.family_restroom;
      default:
        return Icons.location_on;
    }
  }

  void _handlePopupMenuSelection(
      String value,
      String addressId,
      BuildContext context,
      AddressProvider addressProvider,
      ) {
    switch (value) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddEditAddressScreen(addressId: addressId),
          ),
        );
        break;
      case 'set_default':
        addressProvider.setDefaultAddress(addressId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Адрес установлен как основной'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'delete':
        _showDeleteDialog(context, addressId, addressProvider);
        break;
    }
  }

  void _showDeleteDialog(
      BuildContext context,
      String addressId,
      AddressProvider addressProvider,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить адрес?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              addressProvider.removeAddress(addressId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Адрес удален'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}