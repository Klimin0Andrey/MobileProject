// import 'package:flutter/material.dart';
//
// const textInputDecoration = InputDecoration(
//   fillColor: Colors.white,
//   filled: true,
//   enabledBorder: OutlineInputBorder(
//     borderSide: BorderSide(color: Colors.grey, width: 2.0),
//   ),
//   focusedBorder: OutlineInputBorder(
//     borderSide: BorderSide(color: Colors.orange, width: 2.0),
//   ),
// );

// lib/shared/constants.dart

import 'package:flutter/material.dart';

// ✅ ОБНОВЛЕННЫЙ СТИЛЬ ДЛЯ ПОЛЕЙ ВВОДА
const textInputDecoration = InputDecoration(
  // Светло-серый фон, чтобы поле было видно на белом фоне
  fillColor: Color(0xFFF2F2F2),
  filled: true,

  // Стиль для подсказки (hintText)
  hintStyle: TextStyle(color: Colors.grey),

  // Рамка, когда поле не в фокусе (обычное состояние)
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
  ),

  // Рамка, когда пользователь печатает в поле (в фокусе)
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.orange, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
  ),

  // Рамка в случае ошибки валидации
  errorBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.red, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
  ),

  // Рамка в случае ошибки и в фокусе
  focusedErrorBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.red, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
  ),
);