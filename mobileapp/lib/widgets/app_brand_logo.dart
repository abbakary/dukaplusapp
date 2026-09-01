import 'package:flutter/material.dart';

/// DukaMkononi brand logo — [assets/images/brand_logo.png].
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.height = 48,
    this.width,
    this.borderRadius = 10,
    this.showShadow = false,
    this.fit = BoxFit.contain,
  });

  final double height;
  final double? width;
  final double borderRadius;
  final bool showShadow;
  final BoxFit fit;

  static const assetPath = 'assets/images/brand_logo.png';

  @override
  Widget build(BuildContext context) {
    final w = width ?? height * 4.2;
    return Container(
      width: w,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: height * 0.12,
                  offset: Offset(0, height * 0.05),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        width: w,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF0F2347),
          alignment: Alignment.center,
          child: Text(
            'DukaMkononi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: height * 0.22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Square launcher-style mark for avatars / tight slots.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 40, this.borderRadius = 12});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        AppBrandLogo.assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFF0F2347),
          alignment: Alignment.center,
          child: const Text('D+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
