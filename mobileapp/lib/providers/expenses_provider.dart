import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/expense_model.dart';
import 'api_provider.dart';

final expensesRefreshProvider = StateProvider<int>((ref) => 0);

final expensesProvider = FutureProvider.autoDispose<List<ExpenseItem>>((ref) async {
  ref.watch(expensesRefreshProvider);
  final api = ref.read(apiClientProvider);
  final raw = await api.getExpenses();
  return raw.map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>)).toList();
});
