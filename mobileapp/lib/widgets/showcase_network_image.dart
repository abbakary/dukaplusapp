import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image with gradient/icon fallback (handles web CORS/decode failures).
class ShowcaseNetworkImage extends StatelessWidget {
  const ShowcaseNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final BoxFit fit;

  static Widget fallback({IconData icon = Icons.storefront_rounded}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0d9488), Color(0xFF0f766e)],
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white54, size: 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return fallback();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => fallback(),
    );
  }
}
