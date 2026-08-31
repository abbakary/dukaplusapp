import '../../data/models/dashboard_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';

/// Build top-selling products from live sales when API payload is incomplete.
List<TopProduct> computeTopProductsFromSales(
  List<SaleTransaction> sales,
  List<Product> products, {
  int limit = 5,
}) {
  final namesById = {for (final p in products) p.id: p.name};

  final volume = <String, ({double qty, double revenue, String name})>{};
  for (final sale in sales) {
    for (final item in sale.items) {
      if (item.productId.isEmpty) continue;
      final cur = volume[item.productId] ?? (qty: 0.0, revenue: 0.0, name: '');
      final name = item.productName.isNotEmpty
          ? item.productName
          : (cur.name.isNotEmpty ? cur.name : (namesById[item.productId] ?? ''));
      volume[item.productId] = (
        qty: cur.qty + item.quantity,
        revenue: cur.revenue + item.total,
        name: name,
      );
    }
  }

  final sorted = volume.entries.toList()
    ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));

  return sorted.take(limit).map((e) {
    final name = e.value.name.isNotEmpty ? e.value.name : (namesById[e.key] ?? 'Product');
    return TopProduct(
      id: e.key,
      name: name,
      revenue: e.value.revenue,
      quantity: e.value.qty.round(),
    );
  }).toList();
}

bool topProductsNeedEnrichment(List<TopProduct> products) =>
    products.isEmpty || products.every((p) => !p.isComplete);
