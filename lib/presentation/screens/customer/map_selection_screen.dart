import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:linux_test2/services/location_service.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  // Москва по умолчанию (Кремль)
  LatLng _currentCenter = const LatLng(55.751244, 37.618423);

  bool _isLoadingLocation = true;
  bool _isResolvingAddress = false;

  // Дефолтный текст, чтобы поле не было пустым при старте
  String _addressText = 'Наведите пин на здание';
  Map<String, dynamic>? _selectedAddressData;

  Timer? _debounceTimer;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Пробуем найти юзера, но без фанатизма.
    // Если GPS выключен, останемся на Москве.
    _locateUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _locateUser() async {
    try {
      setState(() => _isLoadingLocation = true);
      final pos = await _locationService.getCurrentLocation();
      if (pos != null) {
        final newPoint = LatLng(pos.latitude, pos.longitude);
        _moveToPosition(newPoint);
      }
    } catch (e) {
      // Ошибка GPS не критична, просто остаемся на месте
      // Но обновим адрес для текущей точки (Москвы)
      _resolveAddress(_currentCenter);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _moveToPosition(LatLng point) {
    if (!mounted) return;
    setState(() {
      _currentCenter = point;
      _searchResults.clear(); // Очищаем поиск
      _searchController.clear(); // Очищаем текст
      FocusScope.of(context).unfocus(); // Убираем клавиатуру
    });
    _mapController.move(point, 17); // Зум поближе
    _resolveAddress(point);
  }

  // Поиск адресов при вводе текста
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    // Ждем 800мс перед запросом (debounce)
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      final results = await _locationService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onPositionChanged(MapCamera position, bool hasGesture) {
    _currentCenter = position.center;

    // Если двигаем карту рукой - скрываем результаты поиска
    if (hasGesture) {
      if (mounted && _searchResults.isNotEmpty) {
        setState(() => _searchResults = []);
        FocusScope.of(context).unfocus();
      }
    }

    // Сбрасываем таймер геокодинга
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    setState(() {
      _isResolvingAddress = true;
      _addressText = 'Определение адреса...'; // Показываем, что идет процесс
    });

    // Геокодинг сработает, когда карта постоит на месте 0.8 сек
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _resolveAddress(_currentCenter);
    });
  }

  Future<void> _resolveAddress(LatLng point) async {
    try {
      final data = await _locationService.getAddressFromCoordinates(point);
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
          if (data != null) {
            _selectedAddressData = data;
            // Берем полный адрес или собираем из кусочков
            _addressText = data['fullAddress'] ?? '${data['street']}, ${data['house']}';
            if (_addressText.trim() == ',') _addressText = 'Адрес не определен';
          } else {
            _addressText = 'Не удалось определить адрес';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
          _addressText = 'Ошибка соединения';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. КАРТА
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15,
              minZoom: 4,
              maxZoom: 18,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.yumyum',
              ),
            ],
          ),

          // 2. ПИН ПО ЦЕНТРУ
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, size: 45, color: Colors.red),
            ),
          ),

          // 3. ПОЛЕ ПОИСКА
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Card(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Поиск (например: Тверская 1)',
                      prefixIcon: const Icon(Icons.search, color: Colors.orange),
                      // Кнопка очистки текста
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                // 4. СПИСОК ПОДСКАЗОК
                if (_searchResults.isNotEmpty || _isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: _isSearching
                        ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(color: Colors.orange))
                    )
                        : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          title: Text(
                            item['fullAddress'] ?? 'Неизвестно',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500), // Увеличил шрифт
                          ),
                          subtitle: Text(
                            item['displayName'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.grey), // Увеличил шрифт
                          ),
                          onTap: () {
                            // При клике летим на точку
                            _moveToPosition(LatLng(item['lat'], item['lng']));
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 5. КНОПКА GPS
          Positioned(
            right: 16,
            bottom: 200, // Поднял повыше, чтобы не перекрывало панель
            child: FloatingActionButton(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              onPressed: _locateUser,
              child: _isLoadingLocation
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                  : const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // 6. НИЖНЯЯ ПАНЕЛЬ
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Выбранный адрес', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _addressText,
                            key: ValueKey(_addressText), // Ключ для анимации смены текста
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isResolvingAddress || _selectedAddressData == null)
                          ? null
                          : () {
                        Navigator.pop(context, _selectedAddressData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isResolvingAddress
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Подтвердить адрес', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}