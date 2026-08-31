import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/dashboard_compute.dart';
import '../data/models/dashboard_model.dart';
import 'api_provider.dart';
import 'products_provider.dart';
import 'sales_provider.dart';

final dashboardRefreshProvider = StateProvider<int>((ref) => 0);

final refreshedDashboardProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final api = ref.read(apiClientProvider);
  final raw = await api.getDashboardStats();
  var stats = DashboardStats.fromJson(raw);

  if (topProductsNeedEnrichment(stats.topProducts)) {
    try {
      final sales = await ref.read(salesProvider.future);
      final products = await ref.read(productsProvider.future);
      final computed = computeTopProductsFromSales(sales, products);
      if (computed.isNotEmpty) {
        stats = stats.copyWith(topProducts: computed);
      }
    } catch (_) {}
  }

  return stats;
});

final dashboardStatsProvider = refreshedDashboardProvider;
