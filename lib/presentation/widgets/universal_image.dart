import 'dart:convert';
import 'package:flutter/material.dart';

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
        // Убираем заголовок "data:image/jpeg;base64,"
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

    // 2. Если это обычная ссылка (http/https)
    if (imageUrl!.startsWith('http')) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
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