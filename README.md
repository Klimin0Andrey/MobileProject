# 🍔 Food Delivery App (MVP)

Полнофункциональное мобильное приложение для доставки еды, разработанное
на **Flutter**.\
Поддерживает **3 роли пользователей:** Клиент, Курьер, Администратор.\
Используются современные технологии: Firebase, Cloudinary,
OpenStreetMap, работа в реальном времени.

![alt
text](https://img.shields.io/badge/Flutter-3.0%2B-blue?logo=flutter)
![alt
text](https://img.shields.io/badge/Firebase-Backend-orange?logo=firebase)
![alt
text](https://img.shields.io/badge/Cloudinary-Images-blue?logo=cloudinary)
![alt
text](https://img.shields.io/badge/Maps-OpenStreetMap-green?logo=openstreetmap)

## ✨ Ключевые возможности

### 👤 Клиент

-   **Меню и рестораны**: просмотр списка, фильтрация по кухне и
    рейтингу, поиск блюд.
-   **Корзина**: добавление товаров, изменение количества, расчет
    итоговой суммы.
-   **Геолокация**: определение местоположения, выбор точки на карте
    (OSM), автодополнение адресов.
-   **Оформление заказа**: оплата картой/наличными.
-   **Отслеживание**: статус заказа и местоположение курьера в реальном
    времени.
-   **Чат**: поддержка и общение с курьером.
-   **Профиль**: история заказов, избранное, адреса, тёмная тема.

### 🛵 Курьер

-   **Статус работы**: онлайн/офлайн.
-   **Заказы**: просмотр доступных заказов и принятие.
-   **Навигация**: построение маршрута через **OSRM API**.
-   **Исполнение**: смена статусов («В пути» → «Завершен»).

### 🛠 Администратор

-   **Меню**: CRUD блюд и ресторанов (фото через Cloudinary).
-   **Пользователи**: просмотр, бан.
-   **Аналитика**: графики заказов и доходов (fl_chart).
-   **Рассылка**: push-уведомления всем пользователям.
-   **Поддержка**: тикеты от пользователей.

## 📱 Скриншоты

```{=html}
<table>
```
```{=html}
<tr>
```
```{=html}
<td align="center">
```
`<b>`{=html}Меню`</b>`{=html}
```{=html}
</td>
```
```{=html}
<td align="center">
```
`<b>`{=html}Корзина`</b>`{=html}
```{=html}
</td>
```
```{=html}
<td align="center">
```
`<b>`{=html}Карта`</b>`{=html}
```{=html}
</td>
```
```{=html}
<td align="center">
```
`<b>`{=html}Курьер`</b>`{=html}
```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
<tr>
```
```{=html}
<td>
```
`<img src="https://res.cloudinary.com/dzdsx5iib/image/upload/v1764187427/xxkypurleyddhnih5un6.png" width="200" />`{=html}
```{=html}
</td>
```
```{=html}
<td>
```
`<img src="https://res.cloudinary.com/dzdsx5iib/image/upload/v1764187594/f9gwjtnr5xh2alpx24qa.png" width="200" />`{=html}
```{=html}
</td>
```
```{=html}
<td>
```
`<img src="https://res.cloudinary.com/dzdsx5iib/image/upload/v1764187600/dmifc5mzyojwhq6ppfxf.png" width="200" />`{=html}
```{=html}
</td>
```
```{=html}
<td>
```
`<img src="https://res.cloudinary.com/dzdsx5iib/image/upload/v1764187608/da0hnt9vlstn2ydji7mc.png" width="200" />`{=html}
```{=html}
</td>
```
```{=html}
</tr>
```
```{=html}
</table>
```
## 🚀 Быстрый старт

### Требования

-   Flutter SDK: **\>= 3.0.0**
-   Dart SDK: **\>= 3.0.0**
-   Android Studio или VS Code

### Установка и запуск

**1. Клонировать репозиторий:**

``` bash
git clone <https://github.com/Klimin0Andrey/MobileProject>
```

**2. Установить зависимости:**

``` bash
flutter pub get
```

**3. Настроить Firebase:** - Поместите файл **google-services.json** →
`android/app/`

**4. Запуск приложения:**

``` bash
flutter run
```

## 📂 Структура проекта

    lib/
    ├── config/             # Конфигурация (Cloudinary, темы)
    ├── core/               # Константы, утилиты
    ├── data/               # Слой данных
    │   ├── models/         # User, Order, Dish, Restaurant
    │   └── repositories/   # Репозитории
    ├── services/           # API, Firebase, Location, Route
    │   ├── auth.dart
    │   ├── database.dart
    │   ├── courier_service.dart
    │   └── ...
    ├── presentation/       # UI слой
    │   ├── providers/      # Provider (State Management)
    │   ├── screens/
    │   │   ├── admin/
    │   │   ├── auth/
    │   │   ├── courier/
    │   │   ├── customer/
    │   │   └── checkout/
    │   └── widgets/        # Переиспользуемые компоненты
    └── main.dart           # Точка входа

## 🏗 Архитектура и Технологии

### 🛠 Стек технологий

-   Provider (State Management)
-   Firebase Firestore
-   Firebase Auth
-   Cloudinary (хранение изображений)
-   flutter_map + latlong2
-   OSRM API
-   firebase_messaging
-   fl_chart

## 🗄 Схема Базы Данных (Firestore)

### users

  Поле        Тип       Описание
  ----------- --------- ----------------------------
  uid         String    ID
  role        String    customer / courier / admin
  isOnline    Boolean   Статус курьера
  fcmToken    String    FCM токен
  addresses   Array     Адреса

### restaurants

  Поле          Тип
  ------------- ---------
  id            String
  name          String
  cuisineType   Array
  imageUrl      String
  isActive      Boolean

### dishes

  Поле           Тип
  -------------- --------
  name           String
  price          Number
  restaurantId   String
  category       String

### orders

  Поле              Тип
  ----------------- -------------------
  userId            String
  courierId         String (nullable)
  status            String
  items             Array
  deliveryAddress   Map
  courierLocation   Map

## ✅ Тестирование

-   Unit Tests: CartProvider, RouteService, модели
-   Widget Tests: DishCard, экран логина
-   Integration Tests: добавление товара в корзину

## 👨‍💻 Разработчик

**Андрей Климин**, 2025
