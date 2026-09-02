import '../models/cart_model.dart';
import '../models/sale_model.dart';

/// Canonical API payload — mirrors web `saleToApiPayload` / backend `SaleCreate`.
Map<String, dynamic> saleToApiPayload({
  required CartState cart,
  required List<Map<String, dynamic>> payments,
  required SaleType type,
  required String clientTransactionId,
  bool finalize = true,
  String? branchId,
  double discountAmount = 0,
}) {
  final discount = discountAmount > 0
      ? discountAmount
      : cart.items.fold<double>(0, (s, i) => s + i.discountAmount);
  return {
    'items': cart.items
        .map((i) => {
              'product_id': i.product.id,
              'product_name': i.product.name,
              'quantity': i.quantity,
              'unit_price': i.effectiveUnitPrice,
              'total': i.lineTotal,
              'discount_percent': i.discountPercent,
              'original_unit_price': i.product.price,
            })
        .toList(),
    'discount_amount': discount,
    'customer_id': cart.customerId,
    'customer_name': cart.customerName,
    'payments': payments,
    'sale_type': type.name,
    'branch_id': branchId ?? cart.tableId,
    'client_id': clientTransactionId,
    'finalize': finalize,
  };
}

String generateClientTransactionId() =>
    'txn-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';

bool shouldDeductStock(SaleStatus status) =>
    status == SaleStatus.completed || status == SaleStatus.pendingCredit;
