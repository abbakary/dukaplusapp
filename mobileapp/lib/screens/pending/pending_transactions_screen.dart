import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/services/open_transaction_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bi_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/products_provider.dart';
import '../../providers/pos_resume_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/api_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/shell_insets.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class PendingTransactionsScreen extends ConsumerWidget {
  const PendingTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final pendingAsync = ref.watch(pendingSalesProvider);
    final draftsAsync = ref.watch(openDraftsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.uncompletedSales,
        subtitle: l10n.pendingSubtitle,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(salesRefreshProvider.notifier).state++;
          ref.read(openDraftsRefreshProvider.notifier).state++;
        },
        child: pendingAsync.when(
          loading: () => const ShimmerList(),
          error: (e, _) => _ErrorList(
            message: e.toString(),
            retryLabel: l10n.retry,
            onRetry: () {
              ref.read(salesRefreshProvider.notifier).state++;
              ref.read(openDraftsRefreshProvider.notifier).state++;
            },
          ),
          data: (apiSales) {
            final drafts = draftsAsync.maybeWhen(
              data: (d) => _dedupeDrafts(d.where((x) => x.isPending).toList()),
              orElse: () => <OpenTransactionDraft>[],
            );
            final pendingApi = apiSales
                .where((s) =>
                    s.status == SaleStatus.pendingCompletion ||
                    s.status == SaleStatus.open ||
                    s.status == SaleStatus.requiresAttention ||
                    s.status == SaleStatus.readyToComplete)
                .toList();

            if (drafts.isEmpty && pendingApi.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.pending_actions_outlined,
                    title: l10n.noPendingSales,
                    subtitle: l10n.pendingHint,
                  ),
                ],
              );
            }

            final totalCount = drafts.length + pendingApi.length;
            final rows = _pendingRows(drafts.length, pendingApi.length);

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                switch (row.kind) {
                  case _PendingRowKind.hero:
                    return Column(
                      children: [
                        _HeroBanner(count: totalCount, l10n: l10n),
                        const SizedBox(height: 16),
                      ],
                    );
                  case _PendingRowKind.draftHeader:
                    return _SectionHeader(l10n.localDrafts);
                  case _PendingRowKind.draftSpacer:
                    return const SizedBox(height: 8);
                  case _PendingRowKind.draft:
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DraftCard(draft: drafts[row.index]),
                    );
                  case _PendingRowKind.sectionGap:
                    return const SizedBox(height: 16);
                  case _PendingRowKind.apiHeader:
                    return _SectionHeader(l10n.serverPending);
                  case _PendingRowKind.apiSpacer:
                    return const SizedBox(height: 8);
                  case _PendingRowKind.api:
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PendingSaleCard(sale: pendingApi[row.index]),
                    );
                }
              },
            );
          },
        ),
      ),
      floatingActionButton: ShellFab(
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/pos'),
          icon: const Icon(Icons.point_of_sale_rounded),
          label: Text(l10n.openPos),
        ),
      ),
    );
  }
}

enum _PendingRowKind {
  hero,
  draftHeader,
  draftSpacer,
  draft,
  sectionGap,
  apiHeader,
  apiSpacer,
  api,
}

class _PendingRow {
  final _PendingRowKind kind;
  final int index;
  const _PendingRow(this.kind, [this.index = 0]);
}

List<_PendingRow> _pendingRows(int draftCount, int apiCount) {
  final rows = <_PendingRow>[const _PendingRow(_PendingRowKind.hero)];
  if (draftCount > 0) {
    rows.add(const _PendingRow(_PendingRowKind.draftHeader));
    rows.add(const _PendingRow(_PendingRowKind.draftSpacer));
    for (var i = 0; i < draftCount; i++) {
      rows.add(_PendingRow(_PendingRowKind.draft, i));
    }
    rows.add(const _PendingRow(_PendingRowKind.sectionGap));
  }
  if (apiCount > 0) {
    rows.add(const _PendingRow(_PendingRowKind.apiHeader));
    rows.add(const _PendingRow(_PendingRowKind.apiSpacer));
    for (var i = 0; i < apiCount; i++) {
      rows.add(_PendingRow(_PendingRowKind.api, i));
    }
  }
  return rows;
}

List<OpenTransactionDraft> _dedupeDrafts(List<OpenTransactionDraft> drafts) {
  final seen = <String>{};
  final out = <OpenTransactionDraft>[];
  for (final d in drafts) {
    if (seen.add(d.id)) out.add(d);
  }
  return out;
}

class _HeroBanner extends StatelessWidget {
  final int count;
  final AppLocalizations l10n;
  const _HeroBanner({required this.count, required this.l10n});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.85)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.uncompletedTransactions,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text(
                    l10n.needAttentionCount(count),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary));
}

class _ErrorList extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  const _ErrorList({required this.message, required this.onRetry, required this.retryLabel});

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 40, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

Future<CartState> _buildCartFromSale(
  WidgetRef ref,
  SaleTransaction sale,
) async {
  final products = await ref.read(productsProvider.future);
  final customers = await ref.read(customersProvider.future);
  final items = <CartItem>[];

  for (final item in sale.items) {
    Product? product;
    for (final p in products) {
      if (p.id == item.productId) {
        product = p;
        break;
      }
    }
    product ??= Product(
      id: item.productId,
      name: item.productName,
      category: 'General',
      sku: item.productId,
      price: item.unitPrice,
      cost: item.unitPrice * 0.7,
      stock: 0,
      reorderPoint: 10,
      unit: 'pcs',
      businessType: 'retail',
    );
    items.add(CartItem(product: product, quantity: item.quantity));
  }

  var cart = CartState(items: items);
  cart = _attachCustomer(cart, sale, customers);
  return cart;
}

CartState _attachCustomer(
  CartState cart,
  SaleTransaction sale,
  List<Customer> customers,
) {
  Customer? matched;
  if (sale.customerId != null) {
    for (final c in customers) {
      if (c.id == sale.customerId) {
        matched = c;
        break;
      }
    }
  }
  if (matched == null && sale.customerName != null) {
    final target = sale.customerName!.trim().toLowerCase();
    for (final c in customers) {
      if (c.name.trim().toLowerCase() == target) {
        matched = c;
        break;
      }
    }
  }
  if (matched != null) {
    return cart.setCustomer(matched.id, matched.name);
  }
  if (sale.customerId != null && sale.customerName != null) {
    return cart.setCustomer(sale.customerId!, sale.customerName!);
  }
  if (sale.customerName != null &&
      !sale.customerName!.toLowerCase().contains('walk-in')) {
    return cart.setCustomer(
      sale.customerId ?? 'named-${sale.customerName!.hashCode}',
      sale.customerName!,
    );
  }
  return cart;
}

Future<void> resumeDraftInPos(
  WidgetRef ref,
  OpenTransactionDraft draft,
) async {
  final products = await ref.read(productsProvider.future);
  final customers = await ref.read(customersProvider.future);
  final svc = ref.read(openTransactionServiceProvider);
  var cart = svc.restoreCart(draft, products);

  if (draft.customerId != null || draft.customerName != null) {
    Customer? matched;
    if (draft.customerId != null) {
      for (final c in customers) {
        if (c.id == draft.customerId) {
          matched = c;
          break;
        }
      }
    }
    if (matched == null && draft.customerName != null) {
      final target = draft.customerName!.trim().toLowerCase();
      for (final c in customers) {
        if (c.name.trim().toLowerCase() == target) {
          matched = c;
          break;
        }
      }
    }
    if (matched != null) {
      cart = cart.setCustomer(matched.id, matched.name);
    } else if (draft.customerId != null && draft.customerName != null) {
      cart = cart.setCustomer(draft.customerId!, draft.customerName!);
    } else if (draft.customerName != null) {
      cart = cart.setCustomer(
        draft.customerId ?? 'draft-${draft.id.hashCode}',
        draft.customerName!,
      );
    }
  }

  ref.read(posResumeProvider.notifier).setResume(
        cart: cart,
        draftId: draft.id,
      );
  final user = ref.read(currentUserProvider);
  final tenantId = user?.businessId ?? user?.id ?? 'default';
  await svc.remove(tenantId, draft.id);
  ref.read(openDraftsRefreshProvider.notifier).state++;
}

Future<void> resumeSaleInPos(WidgetRef ref, SaleTransaction sale) async {
  final cart = await _buildCartFromSale(ref, sale);
  ref.read(posResumeProvider.notifier).setResume(
        cart: cart,
        saleId: sale.id,
      );
}

List<Map<String, dynamic>> _paymentsForFinalize(SaleTransaction sale, {String? reference}) {
  if (sale.payments.isNotEmpty) {
    return sale.payments
        .map((p) => {
              'method': p.method,
              'amount': p.amount > 0 ? p.amount : sale.total,
              if ((reference ?? p.reference) != null)
                'reference': reference ?? p.reference,
            })
        .toList();
  }
  return [
    {
      'method': 'cash',
      'amount': sale.total,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
    }
  ];
}

class _DraftCard extends ConsumerWidget {
  final OpenTransactionDraft draft;
  const _DraftCard({required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final itemCount = draft.cart.fold<double>(0, (s, l) => s + l.quantity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            draft.clientTransactionId.length > 12
                                ? draft.clientTransactionId.substring(0, 12)
                                : draft.clientTransactionId,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(l10n.localDraft,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning)),
                        ),
                      ],
                    ),
                    Text(
                      draft.customerName ?? l10n.genericCustomer,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      l10n.itemsUnits(draft.cart.length, itemCount.toStringAsFixed(0)),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await resumeDraftInPos(ref, draft);
                if (context.mounted) context.go('/pos');
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(l10n.resumeInPos),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSaleCard extends ConsumerWidget {
  final SaleTransaction sale;
  const _PendingSaleCard({required this.sale});

  Future<void> _quickComplete(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(appLocalizationsProvider);
    final refCtrl = TextEditingController();
    final method = sale.payments.isNotEmpty ? sale.payments.first.method : 'cash';
    final methodLabel = l10n.paymentMethodLabel(method);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.quickComplete,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('#${sale.receiptNumber} · ${AppFormatters.tsh(sale.total)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              if (sale.customerName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 6),
                    Text(sale.customerName!,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(l10n.paymentLabel(methodLabel.toUpperCase(), AppFormatters.tsh(sale.total)),
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: refCtrl,
                decoration: InputDecoration(
                  labelText: l10n.paymentReference,
                  hintText: 'M-Pesa code / receipt #',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.complete),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom),
            ],
          ),
        ),
      ),
    );

    final reference = refCtrl.text.trim();
    refCtrl.dispose();
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.finalizeSale(sale.id, {
        'payments': _paymentsForFinalize(sale, reference: reference),
        if (sale.customerId != null) 'customer_id': sale.customerId,
        if (sale.customerName != null) 'customer_name': sale.customerName,
      });
      ref.read(salesRefreshProvider.notifier).state++;
      if (context.mounted) {
        final l10nDone = ref.read(appLocalizationsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10nDone.saleCompleted),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10nErr = ref.read(appLocalizationsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10nErr.failedMessage(e.toString())),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('#${sale.receiptNumber}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sale.status.name.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sale.customerName ?? l10n.walkInCustomer,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.itemsCount(sale.items.length),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(
                AppFormatters.tsh(sale.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await resumeSaleInPos(ref, sale);
                    if (context.mounted) context.go('/pos');
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n.resumeInPos),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _quickComplete(context, ref),
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: Text(l10n.quickComplete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
