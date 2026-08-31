import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/sale_model.dart';
import '../data/models/cart_model.dart';
import '../data/models/user_model.dart';
import '../core/constants/app_constants.dart';
import '../data/services/sale_payload.dart';
import '../data/services/offline_sync_service.dart';
import 'api_provider.dart';

final salesRefreshProvider = StateProvider<int>((ref) => 0);

final salesProvider = FutureProvider.autoDispose<List<SaleTransaction>>((ref) async {
  ref.watch(salesRefreshProvider);
  final api = ref.read(apiClientProvider);
  final raw = await api.getSales();
  return raw
      .map((e) => SaleTransaction.fromJson(e as Map<String, dynamic>))
      .toList();
});

final pendingSalesProvider = FutureProvider.autoDispose<List<SaleTransaction>>((ref) async {
  ref.keepAlive();
  ref.watch(salesRefreshProvider);
  final api = ref.read(apiClientProvider);
  final raw = await api.getSales(
    status: 'pending',
    params: const {'limit': 100},
  );
  return raw
      .map((e) => SaleTransaction.fromJson(e as Map<String, dynamic>))
      .toList();
});

class SalesNotifier extends StateNotifier<List<SaleTransaction>> {
  SalesNotifier() : super([]);
  void prepend(SaleTransaction sale) => state = [sale, ...state];
}

final salesListProvider =
    StateNotifierProvider<SalesNotifier, List<SaleTransaction>>(
  (ref) => SalesNotifier(),
);

class CompleteSaleParams {
  final CartState cart;
  final List<Map<String, dynamic>> payments;
  final SaleType type;
  final AuthUser cashier;
  final bool finalize;

  const CompleteSaleParams({
    required this.cart,
    required this.payments,
    required this.type,
    required this.cashier,
    this.finalize = true,
  });
}

class CompleteSaleNotifier extends StateNotifier<AsyncValue<SaleTransaction?>> {
  final Ref _ref;

  CompleteSaleNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<SaleTransaction?> execute(CompleteSaleParams params) async {
    state = const AsyncValue.loading();
    try {
      final clientId = generateClientTransactionId();
      final vatAmount = params.cart.subtotal * AppConstants.defaultVatRate;
      final paid = params.payments.fold<double>(
          0, (s, p) => s + (double.tryParse(p['amount'].toString()) ?? 0));

      final payload = saleToApiPayload(
        cart: params.cart,
        payments: params.payments,
        type: params.type,
        clientTransactionId: clientId,
        finalize: params.finalize,
      );

      SaleTransaction sale;
      try {
        final api = _ref.read(apiClientProvider);
        final raw = await api.createSale(payload);
        sale = SaleTransaction.fromJson(raw);
      } catch (_) {
        sale = _buildLocalSale(params, clientId, vatAmount, paid);
        final sync = OfflineSyncService(_ref.read(apiClientProvider));
        await sync.enqueue({
          'entity_type': 'sale',
          'entity_id': clientId,
          'action': 'create',
          'payload': payload,
          'client_timestamp': DateTime.now().toIso8601String(),
        });
      }

      _ref.read(salesListProvider.notifier).prepend(sale);
      _ref.read(salesRefreshProvider.notifier).state++;
      state = AsyncValue.data(sale);
      return sale;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  SaleTransaction _buildLocalSale(
    CompleteSaleParams p,
    String clientId,
    double vatAmount,
    double paid,
  ) =>
      SaleTransaction(
        id: clientId,
        receiptNumber: 'LOCAL-${clientId.substring(clientId.length - 8).toUpperCase()}',
        date: DateTime.now(),
        customerId: p.cart.customerId,
        customerName: p.cart.customerName,
        items: p.cart.items
            .map((i) => SaleItem(
                  productId: i.product.id,
                  productName: i.product.name,
                  quantity: i.quantity,
                  unitPrice: i.product.price,
                  total: i.lineTotal,
                ))
            .toList(),
        subtotal: p.cart.subtotal,
        vatAmount: vatAmount,
        total: p.cart.total,
        paidAmount: paid,
        balanceRemaining: p.cart.total - paid,
        payments: p.payments
            .map((x) => PaymentBreakdown(
                  method: x['method'].toString(),
                  amount: double.tryParse(x['amount'].toString()) ?? 0,
                  reference: x['reference']?.toString(),
                ))
            .toList(),
        type: p.type,
        cashierName: p.cashier.name,
        status: p.finalize ? SaleStatus.completed : SaleStatus.pendingCompletion,
      );
}

final completeSaleProvider =
    StateNotifierProvider<CompleteSaleNotifier, AsyncValue<SaleTransaction?>>(
  (ref) => CompleteSaleNotifier(ref),
);
