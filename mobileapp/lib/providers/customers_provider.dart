import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/customer_model.dart';
import 'api_provider.dart';

final customersRefreshProvider = StateProvider<int>((ref) => 0);

final customersProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  ref.watch(customersRefreshProvider);
  final api = ref.read(apiClientProvider);
  final raw = await api.getCustomers();
  return raw.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
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
