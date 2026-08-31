import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bi/bi_compute.dart';

import '../data/services/open_transaction_service.dart';

import 'auth_provider.dart';

import 'sales_provider.dart';

import 'products_provider.dart';

import 'expenses_provider.dart';

import 'suppliers_provider.dart';

import 'pos_resume_provider.dart';

import 'api_provider.dart';



final biTimeRangeProvider = StateProvider<BiTimeRange>((ref) => BiTimeRange.month);



final biRefreshProvider = StateProvider<int>((ref) => 0);



final biSnapshotProvider = FutureProvider.autoDispose<BiSnapshot>((ref) async {

  ref.watch(biRefreshProvider);

  final range = ref.watch(biTimeRangeProvider);

  final api = ref.read(apiClientProvider);



  try {

    final raw = await api.getAnalyticsSnapshot(range: apiRangeFromBiTimeRange(range));

    return biSnapshotFromApi(raw);

  } catch (_) {

    // Offline / legacy backend — compute locally from cached lists

    final sales = await ref.watch(salesProvider.future);

    final products = await ref.watch(productsProvider.future);

    final expenses = await ref.watch(expensesProvider.future);

    final suppliers = await ref.watch(suppliersProvider.future);

    return buildBiSnapshot(

      sales: sales,

      products: products,

      expenses: expenses,

      suppliers: suppliers,

      range: range,

    );

  }

});



final openTransactionServiceProvider = Provider((_) => OpenTransactionService());



final openDraftsProvider = FutureProvider.autoDispose<List<OpenTransactionDraft>>((ref) async {

  ref.watch(openDraftsRefreshProvider);

  final user = ref.watch(currentUserProvider);

  final tenantId = user?.businessId ?? user?.id ?? 'default';

  final svc = ref.read(openTransactionServiceProvider);

  return svc.load(tenantId);

});



final openDraftsCountProvider = Provider<int>((ref) {

  final drafts = ref.watch(openDraftsProvider);

  return drafts.maybeWhen(

    data: (list) => list.where((d) => d.isPending).length,

    orElse: () => 0,

  );

});

