import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Brand ────────────────────────────────────────────────
  static const Color primary        = Color(0xFF1A3A6B);
  static const Color primaryLight   = Color(0xFF2556A0);
  static const Color primaryDark    = Color(0xFF0F2347);
  static const Color accent         = Color(0xFF2ECC71);
  static const Color accentOrange   = Color(0xFFF39C12);
  static const Color accentRed      = Color(0xFFE74C3C);
  static const Color accentPurple   = Color(0xFF9B59B6);
  static const Color accentTeal     = Color(0xFF1ABC9C);

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color success  = Color(0xFF27AE60);
  static const Color warning  = Color(0xFFF39C12);
  static const Color danger   = Color(0xFFE74C3C);
  static const Color info     = Color(0xFF3498DB);

  // ── Surfaces ─────────────────────────────────────────────────────
  static const Color background      = Color(0xFFF0F4F8);
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFF7F9FC);

  // ── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1A2A4A);
  static const Color textSecondary  = Color(0xFF5A6A8A);
  static const Color textHint       = Color(0xFF9BA8BB);
  static const Color textOnDark     = Color(0xFFFFFFFF);

  // ── Borders ──────────────────────────────────────────────────────
  static const Color border  = Color(0xFFDDE3EC);
  static const Color divider = Color(0xFFEEF2F7);

  // ── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F2347), Color(0xFF1A3A6B), Color(0xFF2556A0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFE67E22), Color(0xFFF39C12)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8E44AD), Color(0xFF9B59B6)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF16A085), Color(0xFF1ABC9C)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ── Business-type palette ─────────────────────────────────────────
  static const Map<String, Color> _bizPrimary = {
    'pharmacy':    Color(0xFF1565C0),
    'supermarket': Color(0xFF2E7D32),
    'retail':      Color(0xFF1A3A6B),
    'hardware':    Color(0xFFBF360C),
    'electronics': Color(0xFF283593),
    'auto_parts':  Color(0xFF4A148C),
    'fashion':     Color(0xFFAD1457),
    'agrovet':     Color(0xFF33691E),
    'beauty':      Color(0xFF880E4F),
    'salon':       Color(0xFF6A1B9A),
    'restaurant':  Color(0xFFBF360C),
    'stationery':  Color(0xFF0277BD),
    'furniture':   Color(0xFF4E342E),
    'service':     Color(0xFF00695C),
    'mixed':       Color(0xFF1A3A6B),
  };

  static const Map<String, List<Color>> _bizGradient = {
    'pharmacy':    [Color(0xFF1565C0), Color(0xFF1976D2)],
    'supermarket': [Color(0xFF2E7D32), Color(0xFF43A047)],
    'retail':      [Color(0xFF1A3A6B), Color(0xFF2556A0)],
    'hardware':    [Color(0xFFBF360C), Color(0xFFD84315)],
    'electronics': [Color(0xFF283593), Color(0xFF3949AB)],
    'auto_parts':  [Color(0xFF4A148C), Color(0xFF6A1B9A)],
    'fashion':     [Color(0xFFAD1457), Color(0xFFD81B60)],
    'agrovet':     [Color(0xFF33691E), Color(0xFF558B2F)],
    'beauty':      [Color(0xFF880E4F), Color(0xFFC2185B)],
    'salon':       [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
    'restaurant':  [Color(0xFFBF360C), Color(0xFFE64A19)],
    'stationery':  [Color(0xFF0277BD), Color(0xFF0288D1)],
    'furniture':   [Color(0xFF4E342E), Color(0xFF6D4C41)],
    'service':     [Color(0xFF00695C), Color(0xFF00897B)],
    'mixed':       [Color(0xFF1A3A6B), Color(0xFF2556A0)],
  };

  static Color forBusiness(String? type) =>
      _bizPrimary[type] ?? primary;

  static LinearGradient gradientForBusiness(String? type) {
    final c = _bizGradient[type] ?? [primary, primaryLight];
    return LinearGradient(
      colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight,
    );
  }
}
