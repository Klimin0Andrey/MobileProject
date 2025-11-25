import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ ДОБАВИТЬ

class UniversalImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // 1. Если это Base64 строка (начинается с data:image)
    if (imageUrl!.startsWith('data:image')) {
      try {
        final base64String = imageUrl!.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildError(),
        );
      } catch (e) {
        return _buildError();
      }
    }

    // 2. Если это обычная ссылка (http/https) - используем кэширование
    if (imageUrl!.startsWith('http')) {
      // ✅ ИСПРАВЛЕНО: Проверяем на infinity перед преобразованием в int
      final int? memCacheWidth = (width != null && width != double.infinity && !width!.isNaN)
          ? width!.toInt()
          : null;
      final int? memCacheHeight = (height != null && height != double.infinity && !height!.isNaN)
          ? height!.toInt()
          : null;

      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => SizedBox(
          width: width,
          height: height,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildError(),
        // ✅ Настройки кэширования
        maxWidthDiskCache: 1000, // Максимальная ширина в кэше
        maxHeightDiskCache: 1000, // Максимальная высота в кэше
        memCacheWidth: memCacheWidth, // ✅ ИСПРАВЛЕНО: Используем проверенное значение
        memCacheHeight: memCacheHeight, // ✅ ИСПРАВЛЕНО: Используем проверенное значение
      );
    }

    return _buildError();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  Widget _buildError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.red),
        );
  }
}