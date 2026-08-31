import 'package:flutter/foundation.dart';

enum SaleType   { full, partial, credit }
enum SaleStatus {
  open,
  pendingCompletion,
  requiresAttention,
  readyToComplete,
  completed,
  pendingCredit,
  cancelled,
}

@immutable
class SaleItem {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double total;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
    productId:   j['product_id']?.toString() ?? '',
    productName: j['product_name']?.toString() ?? '',
    quantity:    _d(j['quantity']),
    unitPrice:   _d(j['unit_price']),
    total:       _d(j['total'] ?? j['total_price']),
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId, 'product_name': productName,
    'quantity': quantity, 'unit_price': unitPrice, 'total': total,
  };

  static double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}

@immutable
class PaymentBreakdown {
  final String method;
  final double amount;
  final String? reference;

  const PaymentBreakdown({
    required this.method,
    required this.amount,
    this.reference,
  });

  factory PaymentBreakdown.fromJson(Map<String, dynamic> j) => PaymentBreakdown(
    method:    j['method']?.toString() ?? 'cash',
    amount:    double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
    reference: j['reference']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'method': method, 'amount': amount, 'reference': reference,
  };
}

@immutable
class SaleTransaction {
  final String id;
  final String receiptNumber;
  final DateTime date;
  final String? customerId;
  final String? customerName;
  final List<SaleItem> items;
  final double subtotal;
  final double vatAmount;
  final double total;
  final double paidAmount;
  final double balanceRemaining;
  final List<PaymentBreakdown> payments;
  final SaleType type;
  final String cashierName;
  final String? traEfdSignature;
  final SaleStatus status;
  final String? tableId;
  final String? branchId;

  const SaleTransaction({
    required this.id,
    required this.receiptNumber,
    required this.date,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.total,
    required this.paidAmount,
    required this.balanceRemaining,
    required this.payments,
    required this.type,
    required this.cashierName,
    this.traEfdSignature,
    required this.status,
    this.tableId,
    this.branchId,
  });

  factory SaleTransaction.fromJson(Map<String, dynamic> j) => SaleTransaction(
    id:               j['id']?.toString() ?? '',
    receiptNumber:    j['receipt_number']?.toString() ?? '',
    date:             j['date'] != null ? DateTime.parse(j['date'].toString()) : DateTime.now(),
    customerId:       j['customer_id']?.toString(),
    customerName:     j['customer_name']?.toString(),
    items:            (j['items'] as List? ?? []).map((e) => SaleItem.fromJson(e as Map<String, dynamic>)).toList(),
    subtotal:         _d(j['subtotal']),
    vatAmount:        _d(j['vat_amount']),
    total:            _d(j['total']),
    paidAmount:       _d(j['paid_amount']),
    balanceRemaining: _d(j['balance_remaining']),
    payments:         (j['payments'] as List? ?? []).map((e) => PaymentBreakdown.fromJson(e as Map<String, dynamic>)).toList(),
    type:             _saleType((j['sale_type'] ?? j['type'])?.toString()),
    cashierName:      j['cashier_name']?.toString() ?? '',
    traEfdSignature:  j['tra_efd_signature']?.toString(),
    status:           _status(j['status']?.toString()),
    tableId:          j['table_id']?.toString(),
    branchId:         j['branch_id']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'receipt_number': receiptNumber,
    'date': date.toIso8601String(),
    'customer_id': customerId, 'customer_name': customerName,
    'items': items.map((e) => e.toJson()).toList(),
    'subtotal': subtotal, 'vat_amount': vatAmount, 'total': total,
    'paid_amount': paidAmount, 'balance_remaining': balanceRemaining,
    'payments': payments.map((e) => e.toJson()).toList(),
    'type': type.name, 'cashier_name': cashierName,
    'tra_efd_signature': traEfdSignature,
    'status': status.name, 'branch_id': branchId,
  };

  static double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
  static SaleType _saleType(String? s) {
    switch (s) { case 'partial': return SaleType.partial; case 'credit': return SaleType.credit; default: return SaleType.full; }
  }
  static SaleStatus _status(String? s) {
    switch (s) {
      case 'open':
        return SaleStatus.open;
      case 'pending_completion':
        return SaleStatus.pendingCompletion;
      case 'requires_attention':
        return SaleStatus.requiresAttention;
      case 'ready_to_complete':
        return SaleStatus.readyToComplete;
      case 'pending_credit':
        return SaleStatus.pendingCredit;
      case 'cancelled':
        return SaleStatus.cancelled;
      default:
        return SaleStatus.completed;
    }
  }
}
