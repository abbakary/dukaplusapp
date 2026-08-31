import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/supplier_model.dart';
import 'api_provider.dart';

final suppliersRefreshProvider = StateProvider<int>((ref) => 0);

final suppliersProvider = FutureProvider.autoDispose<List<Supplier>>((ref) async {
  ref.watch(suppliersRefreshProvider);
  final api = ref.read(apiClientProvider);
  final raw = await api.getSuppliers();
  return raw.map((e) => Supplier.fromJson(e as Map<String, dynamic>)).toList();
});
