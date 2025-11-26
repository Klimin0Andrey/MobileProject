import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:linux_test2/services/route_service.dart';

void main() {
  late RouteService routeService;

  setUp(() {
    routeService = RouteService();
  });

  group('RouteService Logic Tests', () {
    // 1. Тест: Расстояние между одной и той же точкой должно быть 0
    test('calculateDistance returns 0 for the same point', () {
      final point = LatLng(55.7558, 37.6173); // Москва
      final distance = routeService.calculateDistance(point, point);

      expect(distance, 0.0);
    });

    // 2. Тест: Расстояние между двумя точками (примерное)
    test('calculateDistance returns approximately correct meters', () {
      // Точка А: Красная площадь
      final start = LatLng(55.7539, 37.6208);
      // Точка Б: Большой театр (рядом, ~500-600 метров)
      final end = LatLng(55.7602, 37.6186);

      final distance = routeService.calculateDistance(start, end);

      // Проверяем, что расстояние в адекватных пределах (например, от 500 до 800 метров)
      // Точное число зависит от алгоритма, поэтому проверяем диапазон
      expect(distance, greaterThan(500));
      expect(distance, lessThan(1000));
    });

    // 3. Тест: Расчет времени (Математика: t = s / v)
    test('calculateEstimatedTime calculates minutes correctly based on 30km/h', () {
      // Расстояние 30 км (нужно создать точки с таким расстоянием)
      // Но проще проверить логику на малом расстоянии.

      // Возьмем те же точки (дистанция ~700м = 0.7км)
      // Скорость 30 км/ч.
      // Время = 0.7 / 30 * 60 = ~1.4 минуты -> округляем до 1 или 2.

      final start = LatLng(55.7539, 37.6208);
      final end = LatLng(55.7602, 37.6186);

      final minutes = routeService.calculateEstimatedTime(start, end);

      // Ожидаем, что это займет 1-3 минуты
      expect(minutes, inInclusiveRange(1, 3));
    });
  });
}