import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_model.dart';
import '../data/models/product_model.dart';
import '../core/config/business_settings.dart';
import 'business_settings_provider.dart';

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

  void updateUnitPriceOverride(String productId, double? price) =>
      state = state.updateUnitPriceOverride(productId, price);

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

final cartTotalsProvider = Provider<CartTotals>((ref) {
  final cart = ref.watch(cartProvider);
  final settings = ref.watch(businessSettingsProvider);
  var gross = 0.0;
  var net = 0.0;
  for (final item in cart.items) {
    gross += item.product.price * item.quantity;
    final pct = settings.capDiscount(item.discountPercent);
    net += item.effectiveUnitPrice * item.quantity * (1 - pct / 100);
  }
  return computeCartTotals(
    grossSubtotal: gross,
    discountedSubtotal: net,
    settings: settings,
  );
});

/// Product queued from inventory → POS (sell action).
final posPendingProductProvider = StateProvider<Product?>((ref) => null);
