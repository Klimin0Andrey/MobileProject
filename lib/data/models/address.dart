// lib/data/models/address.dart
import 'package:equatable/equatable.dart';

class DeliveryAddress extends Equatable {
  final String id;
  final String title;
  final String address;
  final String? apartment;
  final String? entrance;
  final String? floor;
  final String? intercom;
  final String? comment;
  final bool isDefault;
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  const DeliveryAddress({
    required this.id,
    required this.title,
    required this.address,
    this.apartment,
    this.entrance,
    this.floor,
    this.intercom,
    this.comment,
    required this.isDefault,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    address,
    apartment,
    entrance,
    floor,
    intercom,
    comment,
    isDefault,
    lat,
    lng,
    createdAt
  ];

  // Конструктор для создания нового адреса
  DeliveryAddress.create({
    required this.title,
    required this.address,
    this.apartment,
    this.entrance,
    this.floor,
    this.intercom,
    this.comment,
    this.isDefault = false,
    this.lat,
    this.lng,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now();

  // Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'apartment': apartment,
      'entrance': entrance,
      'floor': floor,
      'intercom': intercom,
      'comment': comment,
      'isDefault': isDefault,
      'lat': lat,
      'lng': lng,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Создание из Map из Firestore
  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      address: map['address'] ?? '',
      apartment: map['apartment'],
      entrance: map['entrance'],
      floor: map['floor'],
      intercom: map['intercom'],
      comment: map['comment'],
      isDefault: map['isDefault'] ?? false,
      lat: map['lat'],
      lng: map['lng'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  // Копирование с изменениями
  DeliveryAddress copyWith({
    String? title,
    String? address,
    String? apartment,
    String? entrance,
    String? floor,
    String? intercom,
    String? comment,
    bool? isDefault,
    double? lat,
    double? lng,
  }) {
    return DeliveryAddress(
      id: id,
      title: title ?? this.title,
      address: address ?? this.address,
      apartment: apartment ?? this.apartment,
      entrance: entrance ?? this.entrance,
      floor: floor ?? this.floor,
      intercom: intercom ?? this.intercom,
      comment: comment ?? this.comment,
      isDefault: isDefault ?? this.isDefault,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt,
    );
  }

  // Полный адрес для отображения
  String get fullAddress {
    String full = address;
    if (apartment != null && apartment!.isNotEmpty) {
      full += ', кв. $apartment';
    }
    if (entrance != null && entrance!.isNotEmpty) {
      full += ', подъезд $entrance';
    }
    if (floor != null && floor!.isNotEmpty) {
      full += ', этаж $floor';
    }
    if (intercom != null && intercom!.isNotEmpty) {
      full += ', домофон $intercom';
    }
    return full;
  }
}