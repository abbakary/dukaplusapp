import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';

const _pendingStatuses = {
  'open',
  'pending_completion',
  'requires_attention',
  'ready_to_complete',
};

String openTransactionsKey(String tenantId) => 'duka_open_transactions_$tenantId';

class OpenTransactionDraft {
  final String id;
  final String clientTransactionId;
  final DateTime updatedAt;
  final List<DraftCartLine> cart;
  final String? customerId;
  final String? customerName;
  final String paymentMode;
  final String selectedPaymentMethod;
  final String amountPaidInput;
  final String status;
  final String? branchId;
  final String? tableId;

  const OpenTransactionDraft({
    required this.id,
    required this.clientTransactionId,
    required this.updatedAt,
    required this.cart,
    this.customerId,
    this.customerName,
    this.paymentMode = 'full',
    this.selectedPaymentMethod = 'cash',
    this.amountPaidInput = '',
    this.status = 'open',
    this.branchId,
    this.tableId,
  });

  factory OpenTransactionDraft.fromJson(Map<String, dynamic> j) =>
      OpenTransactionDraft(
        id: j['id']?.toString() ?? '',
        clientTransactionId: j['clientTransactionId']?.toString() ?? j['id']?.toString() ?? '',
        updatedAt: DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        cart: (j['cart'] as List? ?? [])
            .map((e) => DraftCartLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        customerId: j['customerId']?.toString(),
        customerName: j['customerName']?.toString(),
        paymentMode: j['paymentMode']?.toString() ?? 'full',
        selectedPaymentMethod: j['selectedPaymentMethod']?.toString() ?? 'cash',
        amountPaidInput: j['amountPaidInput']?.toString() ?? '',
        status: j['status']?.toString() ?? 'open',
        branchId: j['branchId']?.toString(),
        tableId: j['tableId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientTransactionId': clientTransactionId,
        'updatedAt': updatedAt.toIso8601String(),
        'cart': cart.map((c) => c.toJson()).toList(),
        'customerId': customerId,
        'customerName': customerName,
        'paymentMode': paymentMode,
        'selectedPaymentMethod': selectedPaymentMethod,
        'amountPaidInput': amountPaidInput,
        'status': status,
        'branchId': branchId,
        'tableId': tableId,
      };

  bool get isPending => _pendingStatuses.contains(status);
}

class DraftCartLine {
  final String productId;
  final double quantity;
  final double discountPercent;

  const DraftCartLine({
    required this.productId,
    required this.quantity,
    this.discountPercent = 0,
  });

  factory DraftCartLine.fromJson(Map<String, dynamic> j) => DraftCartLine(
        productId: j['productId']?.toString() ?? '',
        quantity: double.tryParse(j['quantity']?.toString() ?? '1') ?? 1,
        discountPercent:
            double.tryParse(j['discountPercent']?.toString() ?? '0') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        'discountPercent': discountPercent,
      };
}

String generateClientTransactionId() {
  final id = const Uuid().v4();
  return 'txn-${DateTime.now().millisecondsSinceEpoch}-${id.substring(0, 8)}';
}

class OpenTransactionService {
  Future<List<OpenTransactionDraft>> load(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(openTransactionsKey(tenantId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final seen = <String>{};
      final drafts = <OpenTransactionDraft>[];
      for (final entry in list) {
        final draft =
            OpenTransactionDraft.fromJson(entry as Map<String, dynamic>);
        if (draft.id.isEmpty || seen.contains(draft.id)) continue;
        seen.add(draft.id);
        drafts.add(draft);
      }
      if (drafts.length != list.length) {
        await save(tenantId, drafts);
      }
      return drafts;
    } catch (_) {
      return [];
    }
  }

  Future<void> save(String tenantId, List<OpenTransactionDraft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      openTransactionsKey(tenantId),
      jsonEncode(drafts.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> upsert(String tenantId, OpenTransactionDraft draft) async {
    final list = await load(tenantId);
    final next = [draft, ...list.where((d) => d.id != draft.id)];
    await save(tenantId, next);
  }

  Future<void> remove(String tenantId, String id) async {
    final list = await load(tenantId);
    await save(tenantId, list.where((d) => d.id != id).toList());
  }

  Future<int> pendingCount(String tenantId) async {
    final list = await load(tenantId);
    return list.where((d) => d.isPending).length;
  }

  OpenTransactionDraft draftFromCart(
    CartState cart, {
    String? id,
    String status = 'open',
    String paymentMode = 'full',
    String selectedPaymentMethod = 'cash',
    String amountPaidInput = '',
  }) {
    final draftId = id ?? generateClientTransactionId();
    return OpenTransactionDraft(
      id: draftId,
      clientTransactionId: draftId,
      updatedAt: DateTime.now(),
      cart: cart.items
          .map((i) => DraftCartLine(
                productId: i.product.id,
                quantity: i.quantity,
                discountPercent: i.discountPercent,
              ))
          .toList(),
      customerId: cart.customerId,
      customerName: cart.customerName,
      paymentMode: paymentMode,
      selectedPaymentMethod: selectedPaymentMethod,
      amountPaidInput: amountPaidInput,
      status: status,
      tableId: cart.tableId,
    );
  }

  CartState restoreCart(OpenTransactionDraft draft, List<Product> products) {
    final items = <CartItem>[];
    for (final line in draft.cart) {
      Product? product;
      for (final p in products) {
        if (p.id == line.productId) {
          product = p;
          break;
        }
      }
      if (product == null) continue;
      items.add(CartItem(
        product: product,
        quantity: line.quantity,
        discountPercent: line.discountPercent,
      ));
    }
    var state = CartState(items: items);
    if (draft.customerId != null && draft.customerName != null) {
      state = state.setCustomer(draft.customerId!, draft.customerName!);
    }
    return state;
  }
}
