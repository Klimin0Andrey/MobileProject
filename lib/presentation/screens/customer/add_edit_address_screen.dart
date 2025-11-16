import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linux_test2/data/models/address.dart';
import 'package:linux_test2/presentation/providers/address_provider.dart';

class AddEditAddressScreen extends StatefulWidget {
  final String? addressId;

  const AddEditAddressScreen({super.key, this.addressId});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _entranceController = TextEditingController();
  final _floorController = TextEditingController();
  final _intercomController = TextEditingController();
  final _commentController = TextEditingController();

  bool _isDefault = false;
  bool _isLoading = false;
  DeliveryAddress? _editingAddress;

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

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);

      if (_editingAddress != null) {
        // Редактирование существующего адреса
        final updatedAddress = _editingAddress!.copyWith(
          title: _titleController.text.trim(),
          address: _addressController.text.trim(),
          apartment: _apartmentController.text.trim().isNotEmpty
              ? _apartmentController.text.trim()
              : null,
          entrance: _entranceController.text.trim().isNotEmpty
              ? _entranceController.text.trim()
              : null,
          floor: _floorController.text.trim().isNotEmpty
              ? _floorController.text.trim()
              : null,
          intercom: _intercomController.text.trim().isNotEmpty
              ? _intercomController.text.trim()
              : null,
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
          isDefault: _isDefault,
        );

        await addressProvider.updateAddress(_editingAddress!.id, updatedAddress);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Адрес успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Добавление нового адреса
        final newAddress = DeliveryAddress.create(
          title: _titleController.text.trim(),
          address: _addressController.text.trim(),
          apartment: _apartmentController.text.trim().isNotEmpty
              ? _apartmentController.text.trim()
              : null,
          entrance: _entranceController.text.trim().isNotEmpty
              ? _entranceController.text.trim()
              : null,
          floor: _floorController.text.trim().isNotEmpty
              ? _floorController.text.trim()
              : null,
          intercom: _intercomController.text.trim().isNotEmpty
              ? _intercomController.text.trim()
              : null,
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
          isDefault: _isDefault,
        );

        await addressProvider.addAddress(newAddress);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Адрес успешно добавлен'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Ошибка при сохранении адреса: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
              // Название адреса
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название адреса *',
                  hintText: 'Например: Дом, Работа, Родители',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название адреса';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Полный адрес
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Адрес *',
                  hintText: 'Например: ул. Ленина, д. 15',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите адрес';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Дополнительные поля в строку
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _apartmentController,
                      decoration: const InputDecoration(
                        labelText: 'Квартира',
                        hintText: '25',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _entranceController,
                      decoration: const InputDecoration(
                        labelText: 'Подъезд',
                        hintText: '3',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      decoration: const InputDecoration(
                        labelText: 'Этаж',
                        hintText: '5',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _intercomController,
                      decoration: const InputDecoration(
                        labelText: 'Домофон',
                        hintText: '124',
                      ),
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
                  hintText: 'Например: После 19:00, код от подъезда...',
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить адрес?'),
        content: const Text('Вы уверены, что хотите удалить этот адрес?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);

              try {
                final addressProvider = Provider.of<AddressProvider>(context, listen: false);
                await addressProvider.removeAddress(_editingAddress!.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Адрес удален'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.of(context).pop();
              } catch (e) {
                setState(() => _isLoading = false);
                _showErrorDialog('Ошибка при удалении адреса: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}