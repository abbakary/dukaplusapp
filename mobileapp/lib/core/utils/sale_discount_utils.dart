import '../../data/models/sale_model.dart';

double computeSaleDiscountAmount(SaleTransaction sale) {
  if (sale.discountAmount > 0) return sale.discountAmount;

  var gross = 0.0;
  var net = 0.0;
  for (final item in sale.items) {
    final orig = item.originalUnitPrice ?? item.unitPrice;
    final pct = item.discountPercent;
    final lineGross = orig * item.quantity;
    final lineNet = item.total > 0 && pct > 0
        ? item.total
        : lineGross * (1 - pct / 100);
    gross += lineGross;
    net += lineNet;
  }
  final fromItems = gross - net;
  if (fromItems > 0.5) return fromItems;

  return 0;
}

double saleGrossSubtotal(SaleTransaction sale) {
  final discount = computeSaleDiscountAmount(sale);
  if (discount > 0 && sale.subtotal > 0) return sale.subtotal + discount;
  return sale.items.fold<double>(
    0,
    (sum, i) => sum + (i.originalUnitPrice ?? i.unitPrice) * i.quantity,
  );
}
