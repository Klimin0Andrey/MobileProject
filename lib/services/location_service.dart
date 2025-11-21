import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationService {
  // 1. Текущая геопозиция
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS отключен');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Нет прав на GPS');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('GPS запрещен навсегда');

    return await Geolocator.getCurrentPosition();
  }

  // 2. Получить адрес по координатам (Reverse Geocoding)
  Future<Map<String, dynamic>?> getAddressFromCoordinates(LatLng point) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&accept-language=ru&zoom=18');

      final response = await http.get(url, headers: {'User-Agent': 'YumYumDelivery/1.0'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseNominatimData(data, point);
      }
    } catch (e) {
      print('Ошибка геокодинга: $e');
    }
    return null;
  }

  // 3. Поиск адреса по тексту (Forward Geocoding)
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.length < 3) return [];

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=ru&accept-language=ru');

      final response = await http.get(url, headers: {'User-Agent': 'YumYumDelivery/1.0'});

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) {
          final lat = double.parse(item['lat']);
          final lng = double.parse(item['lon']);
          return _parseNominatimData(item, LatLng(lat, lng))!;
        }).toList();
      }
    } catch (e) {
      print('Ошибка поиска: $e');
    }
    return [];
  }

  // ✅ УЛУЧШЕННЫЙ ПАРСЕР АДРЕСА ДЛЯ РФ
  Map<String, dynamic>? _parseNominatimData(dynamic data, LatLng point) {
    final address = data['address'];
    if (address == null) return null;

    // 1. Вытаскиваем компоненты
    String city = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['city_district'] ??
        '';

    String street = address['road'] ??
        address['pedestrian'] ??
        address['street'] ??
        address['highway'] ?? // Иногда улицы записаны как highway
        '';

    // Если улицы нет, ищем название объекта (например, "ТЦ Плаза")
    if (street.isEmpty) {
      street = address['amenity'] ?? address['shop'] ?? address['building'] ?? '';
    }

    String houseNumber = address['house_number'] ?? '';

    // 2. Собираем красивую строку "Город, Улица, Дом"
    List<String> parts = [];

    if (city.isNotEmpty) parts.add(city);
    if (street.isNotEmpty) parts.add(street);
    if (houseNumber.isNotEmpty) parts.add(houseNumber); // Просто номер, без "д." так чаще удобнее

    String fullAddress = parts.join(', ');

    // Если адрес получился пустым (бывает в полях), берем display_name, но чистим его
    if (fullAddress.length < 5) {
      fullAddress = data['display_name']?.split(',').take(3).join(',') ?? '';
    }

    return {
      'fullAddress': fullAddress, // Пойдет в поле ввода
      'street': street,
      'house': houseNumber,
      'city': city,
      'lat': point.latitude,
      'lng': point.longitude,
      'displayName': fullAddress // Для списка подсказок
    };
  }
}