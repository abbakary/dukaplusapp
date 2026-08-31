import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';
import 'api_provider.dart';

/// Cached product catalog — survives tab switches; invalidate on explicit refresh.
final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  ref.keepAlive();
  ref.watch(productsRefreshProvider);
  final api = ref.read(apiClientProvider);
  final raw = await api.getProducts(params: const {'limit': 500});
  return raw.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
});

final productsRefreshProvider = StateProvider<int>((ref) => 0);

final refreshedProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  ref.watch(productsRefreshProvider);
  return ref.watch(productsProvider.future);
});

class ProductFilterState {
  final String query;
  final String? category;
  final bool lowStockOnly;
  final bool expiringOnly;

  const ProductFilterState({
    this.query = '',
    this.category,
    this.lowStockOnly = false,
    this.expiringOnly = false,
  });

  ProductFilterState copyWith({
    String? query,
    String? category,
    bool? lowStockOnly,
    bool? expiringOnly,
    bool clearCategory = false,
  }) =>
      ProductFilterState(
        query: query ?? this.query,
        category: clearCategory ? null : (category ?? this.category),
        lowStockOnly: lowStockOnly ?? this.lowStockOnly,
        expiringOnly: expiringOnly ?? this.expiringOnly,
      );
}

final productFilterProvider =
    StateNotifierProvider<ProductFilterNotifier, ProductFilterState>(
  (ref) => ProductFilterNotifier(),
);

class ProductFilterNotifier extends StateNotifier<ProductFilterState> {
  ProductFilterNotifier() : super(const ProductFilterState());

  Timer? _debounce;

  void setQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(query: q);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void setCategory(String? c) =>
      state = state.copyWith(category: c, clearCategory: c == null);
  void toggleLowStock() =>
      state = state.copyWith(lowStockOnly: !state.lowStockOnly);
  void toggleExpiring() =>
      state = state.copyWith(expiringOnly: !state.expiringOnly);
  void reset() => state = const ProductFilterState();
}

final filteredProductsProvider =
    Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final all = ref.watch(refreshedProductsProvider);
  final filter = ref.watch(productFilterProvider);

  return all.whenData((products) {
    var list = products;
    if (filter.query.isNotEmpty) {
      final q = filter.query.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }
    if (filter.category != null) {
      list = list.where((p) => p.category == filter.category).toList();
    }
    if (filter.lowStockOnly) list = list.where((p) => p.isLowStock).toList();
    if (filter.expiringOnly) list = list.where((p) => p.isExpiringSoon).toList();
    return list;
  });
});
