import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/dashboard_compute.dart';
import '../core/utils/ttl_cache.dart';
import '../data/models/dashboard_model.dart';
import 'api_provider.dart';
import 'products_provider.dart';
import 'sales_provider.dart';

// ── Cache: avoid re-fetching within 60 seconds ─────────────────────────────
final _dashCache = TtlCache<DashboardStats>(ttl: const Duration(seconds: 60));

/// Increment to force a refresh (bypasses TTL cache).
final dashboardRefreshProvider = StateProvider<int>((ref) => 0);

/// Main dashboard provider — auto-disposes, cached, parallel-fetch.
final refreshedDashboardProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final generation = ref.watch(dashboardRefreshProvider);

  // Use cached value unless a manual refresh was triggered
  final cached = _dashCache.get();
  if (cached != null && generation == 0) return cached;

  final api = ref.read(apiClientProvider);

  // ── Parallel fetch: dashboard stats + optional enrichment data ──────────
  final result = await Future.any([
    // Fast path: just the dashboard stats endpoint
    _fetchStats(api),
    // Timeout safety — return empty stats if API hangs beyond 15 s
    Future.delayed(
      const Duration(seconds: 15),
      () => DashboardStats.demo(),
    ),
  ]);

  // ── Enrich top products if names are missing ────────────────────────────
  var stats = result;
  if (topProductsNeedEnrichment(stats.topProducts)) {
    try {
      // Run sales + products fetch in parallel — don't block rendering
      final sales    = await ref.read(salesProvider.future)
          .timeout(const Duration(seconds: 8));
      final products = await ref.read(productsProvider.future)
          .timeout(const Duration(seconds: 8));

      final computed = computeTopProductsFromSales(sales, products);
      if (computed.isNotEmpty) {
        stats = stats.copyWith(topProducts: computed);
      }
    } catch (_) {
      // ignore — partial data is fine
    }
  }

  _dashCache.set(stats);
  return stats;
});

Future<DashboardStats> _fetchStats(dynamic api) async {
  final raw  = await api.getDashboardStats();
  return DashboardStats.fromJson(raw as Map<String, dynamic>);
}

// Convenience alias used in a few places
final dashboardStatsProvider = refreshedDashboardProvider;
