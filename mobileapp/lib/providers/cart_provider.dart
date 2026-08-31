import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_model.dart';
import '../data/models/product_model.dart';

/// CartNotifier — fine-grained Riverpod StateNotifier
/// Only widgets that call ref.watch(cartProvider.select(...)) rebuild.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(Product product, {double qty = 1}) =>
      state = state.addItem(product, qty: qty);

  void removeItem(String productId) =>
      state = state.removeItem(productId);

  void updateQty(String productId, double qty) =>
      state = state.updateQty(productId, qty);

  void updateDiscount(String productId, double pct) =>
      state = state.updateDiscount(productId, pct);

  void setCustomer(String id, String name) =>
      state = state.setCustomer(id, name);

  void clearCustomer() =>
      state = state.clearCustomer();

  void clear() => state = const CartState();

  void loadState(CartState cart) => state = cart;

  void setTableContext(String tableId, String label) =>
      state = CartState(
        items: state.items,
        customerId: state.customerId,
        customerName: state.customerName,
        tableId: tableId,
        tableLabel: label,
      );
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

// Selectors — each widget subscribes only to what it needs
final cartItemCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider.select((s) => s.itemCount)),
);
final cartTotalProvider = Provider<double>(
  (ref) => ref.watch(cartProvider.select((s) => s.total)),
);
final cartIsEmptyProvider = Provider<bool>(
  (ref) => ref.watch(cartProvider.select((s) => s.isEmpty)),
);

/// Product queued from inventory → POS (sell action).
final posPendingProductProvider = StateProvider<Product?>((ref) => null);
