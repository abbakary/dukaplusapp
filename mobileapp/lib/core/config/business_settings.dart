import 'package:flutter/foundation.dart';

@immutable
class BusinessSettings {
  final bool discountEnabled;
  final double maxDiscountPercent;
  final bool showDiscountOnReceipts;
  final bool showDiscountOnDocuments;
  final bool vatEnabled;
  final double vatRate;

  const BusinessSettings({
    this.discountEnabled = true,
    this.maxDiscountPercent = 15,
    this.showDiscountOnReceipts = true,
    this.showDiscountOnDocuments = true,
    this.vatEnabled = true,
    this.vatRate = 0.18,
  });

  double capDiscount(double pct) {
    if (!discountEnabled) return 0;
    return pct.clamp(0, maxDiscountPercent);
  }

  BusinessSettings copyWith({
    bool? discountEnabled,
    double? maxDiscountPercent,
    bool? showDiscountOnReceipts,
    bool? showDiscountOnDocuments,
    bool? vatEnabled,
    double? vatRate,
  }) =>
      BusinessSettings(
        discountEnabled: discountEnabled ?? this.discountEnabled,
        maxDiscountPercent: maxDiscountPercent ?? this.maxDiscountPercent,
        showDiscountOnReceipts: showDiscountOnReceipts ?? this.showDiscountOnReceipts,
        showDiscountOnDocuments: showDiscountOnDocuments ?? this.showDiscountOnDocuments,
        vatEnabled: vatEnabled ?? this.vatEnabled,
        vatRate: vatRate ?? this.vatRate,
      );

  Map<String, dynamic> toJson() => {
        'discountEnabled': discountEnabled,
        'maxDiscountPercent': maxDiscountPercent,
        'showDiscountOnReceipts': showDiscountOnReceipts,
        'showDiscountOnDocuments': showDiscountOnDocuments,
        'vatEnabled': vatEnabled,
        'vatRate': vatRate,
      };

  factory BusinessSettings.fromJson(Map<String, dynamic> j) => BusinessSettings(
        discountEnabled: j['discountEnabled'] as bool? ?? true,
        maxDiscountPercent: (j['maxDiscountPercent'] as num?)?.toDouble() ?? 15,
        showDiscountOnReceipts: j['showDiscountOnReceipts'] as bool? ?? true,
        showDiscountOnDocuments: j['showDiscountOnDocuments'] as bool? ?? true,
        vatEnabled: j['vatEnabled'] as bool? ?? true,
        vatRate: (j['vatRate'] as num?)?.toDouble() ?? 0.18,
      );
}

CartTotals computeCartTotals({
  required double grossSubtotal,
  required double discountedSubtotal,
  required BusinessSettings settings,
}) {
  final discountAmount = grossSubtotal - discountedSubtotal;
  final vatAmount = settings.vatEnabled ? discountedSubtotal * settings.vatRate : 0.0;
  return CartTotals(
    grossSubtotal: grossSubtotal,
    subtotal: discountedSubtotal,
    discountAmount: discountAmount,
    vatAmount: vatAmount,
    total: discountedSubtotal + vatAmount,
  );
}

@immutable
class CartTotals {
  final double grossSubtotal;
  final double subtotal;
  final double discountAmount;
  final double vatAmount;
  final double total;

  const CartTotals({
    this.grossSubtotal = 0,
    this.subtotal = 0,
    this.discountAmount = 0,
    this.vatAmount = 0,
    this.total = 0,
  });
}
