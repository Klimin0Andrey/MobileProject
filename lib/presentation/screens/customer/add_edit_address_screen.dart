import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart'; // ✅ Пакет для автозаполнения
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/presentation/providers/address_provider.dart';
import 'package:linux_test2/presentation/screens/customer/map_selection_screen.dart';
import 'package:linux_test2/services/location_service.dart';

class AddEditAddressScreen extends StatefulWidget {
  final String? addressId;

  const AddEditAddressScreen({super.key, this.addressId});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _entranceController = TextEditingController();
  final _floorController = TextEditingController();
  final _intercomController = TextEditingController();
  final _commentController = TextEditingController();

  // Сервис для поиска адресов
  final LocationService _locationService = LocationService();

  bool _isDefault = false;
  bool _isLoading = false;
  DeliveryAddress? _editingAddress;

  // Координаты (важны для карты и сортировки)
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddressData();
    });
  }

  void _loadAddressData() {
    if (widget.addressId != null) {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      final address = addressProvider.getAddressById(widget.addressId!);

      if (address != null) {
        setState(() {
          _editingAddress = address;
          _titleController.text = address.title;
          _addressController.text = address.address;
          _apartmentController.text = address.apartment ?? '';
          _entranceController.text = address.entrance ?? '';
          _floorController.text = address.floor ?? '';
          _intercomController.text = address.intercom ?? '';
          _commentController.text = address.comment ?? '';
          _isDefault = address.isDefault;
          // Загружаем сохраненные координаты
          _lat = address.lat;
          _lng = address.lng;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _apartmentController.dispose();
    _entranceController.dispose();
    _floorController.dispose();
    _intercomController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Открытие карты для выбора точки
  Future<void> _pickFromMap() async {
    // Скрываем клавиатуру перед открытием карты
    FocusScope.of(context).unfocus();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapSelectionScreen()),
    );

    if (result != null && result is Map) {
      setState(() {
        // 1. Заполняем текстовое поле адресом с карты
        if (result['fullAddress'] != null) {
          _addressController.text = result['fullAddress'];
        }
        // 2. Сохраняем координаты
        _lat = result['lat'];
        _lng = result['lng'];
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);

      // Хелпер для создания объекта адреса
      DeliveryAddress createAddressObject() {
        return DeliveryAddress.create(
          title: _titleController.text.trim(),
          address: _addressController.text.trim(),
          apartment: _apartmentController.text.trim().isNotEmpty ? _apartmentController.text.trim() : null,
          entrance: _entranceController.text.trim().isNotEmpty ? _entranceController.text.trim() : null,
          floor: _floorController.text.trim().isNotEmpty ? _floorController.text.trim() : null,
          intercom: _intercomController.text.trim().isNotEmpty ? _intercomController.text.trim() : null,
          comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
          isDefault: _isDefault,
          lat: _lat,
          lng: _lng,
        );
      }

      if (_editingAddress != null) {
        // Обновление
        final updatedAddress = _editingAddress!.copyWith(
          title: _titleController.text.trim(),
          address: _addressController.text.trim(),
          apartment: _apartmentController.text.trim().isNotEmpty ? _apartmentController.text.trim() : null,
          entrance: _entranceController.text.trim().isNotEmpty ? _entranceController.text.trim() : null,
          floor: _floorController.text.trim().isNotEmpty ? _floorController.text.trim() : null,
          intercom: _intercomController.text.trim().isNotEmpty ? _intercomController.text.trim() : null,
          comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
          isDefault: _isDefault,
          lat: _lat,
          lng: _lng,
        );

        await addressProvider.updateAddress(_editingAddress!.id, updatedAddress);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Адрес обновлен'), backgroundColor: Colors.green),
          );
        }
      } else {
        // Создание
        final newAddress = createAddressObject();
        await addressProvider.addAddress(newAddress);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Адрес добавлен'), backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showErrorDialog('Ошибка при сохранении: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить адрес?'),
        content: const Text('Вы уверены, что хотите удалить этот адрес?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);
              try {
                final addressProvider = Provider.of<AddressProvider>(context, listen: false);
                await addressProvider.removeAddress(_editingAddress!.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Адрес удален'), backgroundColor: Colors.red),
                  );
                  Navigator.of(context).pop();
                }
              } catch (e) {
                setState(() => _isLoading = false);
                _showErrorDialog('Ошибка при удалении: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingAddress != null ? 'Редактировать адрес' : 'Добавить адрес'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_editingAddress != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _showDeleteDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Название адреса (Дом, Работа)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название адреса *',
                  hintText: 'Например: Дом, Работа',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Введите название адреса'
                    : null,
              ),
              const SizedBox(height: 16),

              // Кнопка "Указать на карте"
              TextButton.icon(
                onPressed: _pickFromMap,
                icon: const Icon(Icons.map, color: Colors.orange),
                label: const Text(
                  'Указать на карте',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              // ✅ ИСПРАВЛЕННЫЙ БЛОК АВТОЗАПОЛНЕНИЯ (TypeAheadField)
              TypeAheadField<Map<String, dynamic>>(
                controller: _addressController,
                // Логика поиска
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 3) return [];
                  return await _locationService.searchPlaces(pattern);
                },
                // Внешний вид поля ввода (Builder) - ОБЯЗАТЕЛЬНО ДЛЯ НОВОЙ ВЕРСИИ
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Адрес *',
                      hintText: 'Начните вводить (ул. Ленина...)',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    minLines: 1,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите адрес';
                      }
                      return null;
                    },
                  );
                },
                // Внешний вид элемента списка
                itemBuilder: (context, Map<String, dynamic> suggestion) {
                  return ListTile(
                    leading: const Icon(Icons.location_city, color: Colors.grey),
                    title: Text(suggestion['fullAddress'] ?? ''),
                    subtitle: Text(
                      suggestion['displayName'] ?? '',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
                // При выборе элемента
                onSelected: (Map<String, dynamic> suggestion) {
                  _addressController.text = suggestion['fullAddress'];
                  setState(() {
                    _lat = suggestion['lat'];
                    _lng = suggestion['lng'];
                  });
                },
                // Настройки пустого состояния
                emptyBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Адрес не найден', style: TextStyle(color: Colors.grey)),
                ),
                loadingBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                hideOnEmpty: true,
                hideOnError: true,
              ),

              const SizedBox(height: 16),

              // Дополнительные поля (Квартира, Подъезд)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _apartmentController,
                      decoration: const InputDecoration(labelText: 'Квартира'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _entranceController,
                      decoration: const InputDecoration(labelText: 'Подъезд'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Дополнительные поля (Этаж, Домофон)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      decoration: const InputDecoration(labelText: 'Этаж'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _intercomController,
                      decoration: const InputDecoration(labelText: 'Домофон'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Комментарий
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Комментарий для курьера',
                  hintText: 'Например: Код от калитки 1234...',
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Адрес по умолчанию
              SwitchListTile(
                title: const Text('Использовать как основной адрес'),
                subtitle: const Text('Будет автоматически подставляться при заказе'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                activeThumbColor: Colors.orange,
              ),
              const SizedBox(height: 32),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    _editingAddress != null ? 'Сохранить изменения' : 'Добавить адрес',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}