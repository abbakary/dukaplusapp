import 'package:flutter/foundation.dart';
import 'product_model.dart';

@immutable
class CartItem {
  final Product product;
  final double quantity;
  final double discountPercent;
  final double? unitPriceOverride;

  const CartItem({
    required this.product,
    this.quantity = 1,
    this.discountPercent = 0,
    this.unitPriceOverride,
  });

  double get effectiveUnitPrice => unitPriceOverride ?? product.price;

  double get lineTotal {
    final disc = discountPercent / 100;
    return effectiveUnitPrice * quantity * (1 - disc);
  }

  double get originalTotal => effectiveUnitPrice * quantity;
  double get discountAmount => originalTotal - lineTotal;

  CartItem copyWith({
    double? quantity,
    double? discountPercent,
    double? unitPriceOverride,
    bool clearUnitPriceOverride = false,
  }) =>
      CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
        discountPercent: discountPercent ?? this.discountPercent,
        unitPriceOverride:
            clearUnitPriceOverride ? null : (unitPriceOverride ?? this.unitPriceOverride),
      );
}

@immutable
class CartState {
  final List<CartItem> items;
  final String? customerId;
  final String? customerName;
  final String? tableId;
  final String? tableLabel;

  const CartState({
    this.items = const [],
    this.customerId,
    this.customerName,
    this.tableId,
    this.tableLabel,
  });

  double get subtotal => items.fold(0, (s, i) => s + i.lineTotal);
  double get vatAmount => subtotal * 0.18;
  double get total => subtotal + vatAmount;
  int get itemCount => items.length;
  double get totalQty => items.fold(0, (s, i) => s + i.quantity);

  bool get isEmpty => items.isEmpty;
  bool get hasCustomer => customerId != null;

  CartState addItem(Product product, {double qty = 1}) {
    final existing = items.indexWhere((i) => i.product.id == product.id);
    List<CartItem> next;
    if (existing >= 0) {
      next = List.from(items);
      next[existing] = next[existing].copyWith(
        quantity: next[existing].quantity + qty,
      );
    } else {
      next = [...items, CartItem(product: product, quantity: qty)];
    }
    return _copy(items: next);
  }

  CartState removeItem(String productId) =>
      _copy(items: items.where((i) => i.product.id != productId).toList());

  CartState updateQty(String productId, double qty) {
    if (qty <= 0) return removeItem(productId);
    return _copy(
      items: items.map((i) => i.product.id == productId ? i.copyWith(quantity: qty) : i).toList(),
    );
  }

  CartState updateDiscount(String productId, double pct) => _copy(
    items: items.map((i) => i.product.id == productId ? i.copyWith(discountPercent: pct) : i).toList(),
  );

  CartState updateUnitPriceOverride(String productId, double? price) => _copy(
    items: items
        .map((i) => i.product.id == productId
            ? (price == null
                ? i.copyWith(clearUnitPriceOverride: true)
                : i.copyWith(unitPriceOverride: price))
            : i)
        .toList(),
  );

  CartState setCustomer(String id, String name) =>
      _copy(customerId: id, customerName: name);

  CartState clearCustomer() =>
      CartState(items: items, tableId: tableId, tableLabel: tableLabel);

  CartState copyWith({
    List<CartItem>? items,
    String? customerId,
    String? customerName,
  }) => _copy(
    items: items,
    customerId: customerId,
    customerName: customerName,
  );

  CartState clear() => const CartState();

  CartState _copy({
    List<CartItem>? items,
    String? customerId,
    String? customerName,
    String? tableId,
    String? tableLabel,
  }) => CartState(
    items: items ?? this.items,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    tableId: tableId ?? this.tableId,
    tableLabel: tableLabel ?? this.tableLabel,
  );
}
