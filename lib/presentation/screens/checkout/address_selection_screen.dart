import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/presentation/providers/address_provider.dart';
import 'package:linux_test2/presentation/screens/customer/add_edit_address_screen.dart';

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите адрес доставки'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AddressProvider>(
        builder: (context, addressProvider, child) {
          // Получаем список адресов из вашего провайдера
          final addresses = addressProvider.addresses;

          // Если список пуст (или еще грузится, так как isLoading нет в провайдере)
          if (addresses.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = addresses[index];

                    // ✅ Проверяем выбранный адрес через ваш геттер selectedAddress
                    // Используем safe call (?.), так как selectedAddress может быть null
                    final isSelected =
                        address.id == addressProvider.selectedAddress?.id;

                    return _buildAddressCard(
                      context,
                      address,
                      isSelected,
                      addressProvider,
                    );
                  },
                ),
              ),

              // Кнопка добавления внизу
              _buildBottomButton(context),
            ],
          );
        },
      ),
    );
  }

  // Карточка адреса
  Widget _buildAddressCard(
    BuildContext context,
    DeliveryAddress address, // ✅ Используем ваш класс DeliveryAddress
    bool isSelected,
    AddressProvider provider,
  ) {
    return Card(
      elevation: isSelected ? 3 : 0,
      color: isSelected ? Colors.orange[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Colors.orange, width: 1.5)
            : BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // ✅ Используем ваш метод setSelectedAddress
          provider.setSelectedAddress(address);
          Navigator.of(context).pop(address);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Иконка
              CircleAvatar(
                backgroundColor: isSelected ? Colors.orange : Colors.grey[200],
                child: Icon(
                  _getAddressIcon(address.title),
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),

              // Текстовая информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected
                                ? Colors.orange[900]
                                : Colors.black87,
                          ),
                        ),
                        // Если адрес по умолчанию - покажем значок
                        if (address.isDefault)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Основной',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // ✅ Используем ваш геттер fullAddress
                    Text(
                      address.fullAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Кнопка редактирования
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                onPressed: () => _navigateToAddEdit(context, address.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Пустой экран
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 60,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Нет адресов',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Добавьте адрес доставки, чтобы мы знали, куда привезти ваш заказ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAddEdit(context),
                icon: const Icon(Icons.add),
                label: const Text('Добавить первый адрес'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToAddEdit(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text(
              'Добавить новый адрес',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddEdit(BuildContext context, [String? addressId]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(addressId: addressId),
      ),
    );
  }

  IconData _getAddressIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('дом')) return Icons.home_rounded;
    if (lowerTitle.contains('работ') || lowerTitle.contains('офис'))
      return Icons.work_rounded;
    return Icons.location_on_rounded;
  }
}
