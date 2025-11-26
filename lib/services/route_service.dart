import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  // OSRM API endpoint (публичный сервер)
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Рассчитать маршрут между двумя точками через OSRM
  /// Возвращает список точек маршрута (polyline)
  Future<List<LatLng>> calculateRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      // Формат: /route/v1/driving/{lon1},{lat1};{lon2},{lat2}?overview=full&geometries=geojson
      final url = Uri.parse(
        '$_osrmBaseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          // GeoJSON LineString format: [[lon, lat], [lon, lat], ...]
          if (geometry['type'] == 'LineString' && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            return coordinates.map((coord) {
              // OSRM возвращает [longitude, latitude]
              return LatLng(coord[1] as double, coord[0] as double);
            }).toList();
          }
        }
      }

      // Если маршрут не найден, возвращаем прямую линию между точками
      return [start, end];
    } catch (e) {
      print('❌ Ошибка расчета маршрута: $e');
      // В случае ошибки возвращаем прямую линию
      return [start, end];
    }
  }

  /// Рассчитать расстояние между двумя точками (в метрах)
  double calculateDistance(LatLng point1, LatLng point2) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Рассчитать примерное время в пути (в минутах)
  /// Использует среднюю скорость 30 км/ч для города
  int calculateEstimatedTime(LatLng start, LatLng end) {
    final distanceKm = calculateDistance(start, end) / 1000;
    const averageSpeedKmh = 30.0; // Средняя скорость в городе
    final timeHours = distanceKm / averageSpeedKmh;
    return (timeHours * 60).round(); // Возвращаем в минутах
  }
}







