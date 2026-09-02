import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/customer_model.dart';
import '../data/services/tenant_cache_service.dart';
import 'api_provider.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

final _tenantCache = TenantCacheService();

final customersRefreshProvider = StateProvider<int>((ref) => 0);

final customersProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  ref.watch(customersRefreshProvider);
  final user = ref.watch(currentUserProvider);
  final tenantId = user?.businessId ?? user?.id ?? 'default';
  final api = ref.read(apiClientProvider);
  try {
    final raw = await api.getCustomers();
    final customers =
        raw.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
    await _tenantCache.saveCustomers(tenantId, customers);
    ref.read(isOnlineProvider.notifier).setOnline(true);
    return customers;
  } catch (_) {
    ref.read(isOnlineProvider.notifier).setOnline(false);
    final cached = await _tenantCache.loadCustomers(tenantId);
    if (cached != null && cached.isNotEmpty) return cached;
    rethrow;
  }
});

class CustomerSearchNotifier extends StateNotifier<String> {
  CustomerSearchNotifier() : super('');
  void setQuery(String q) => state = q;
}

final customerSearchProvider =
    StateNotifierProvider<CustomerSearchNotifier, String>(
  (ref) => CustomerSearchNotifier(),
);

final filteredCustomersProvider =
    Provider.autoDispose<AsyncValue<List<Customer>>>((ref) {
  final all = ref.watch(customersProvider);
  final query = ref.watch(customerSearchProvider).toLowerCase();

  return all.whenData((customers) {
    if (query.isEmpty) return customers;
    return customers
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.phone.contains(query) ||
            c.email.toLowerCase().contains(query))
        .toList();
  });
});
