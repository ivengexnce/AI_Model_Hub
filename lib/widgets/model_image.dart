import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Fills whatever size its parent gives it.
class ModelImage extends StatelessWidget {
  const ModelImage({
    super.key,
    required this.url,
    this.radius = 0,
    this.memCacheWidth,
  });

  final String url;
  final double radius;
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: c.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.memory_outlined, color: c.outline, size: 28),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.expand(
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: memCacheWidth,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, __) =>
                    ColoredBox(color: c.surfaceContainerHigh),
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}
