import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/product_catalog.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/products_provider.dart';
import '../../core/utils/offline_messages.dart';
import '../../data/services/offline_sync_service.dart';
import '../../providers/api_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/cart_provider.dart';
import '../../data/models/product_model.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/product_qr_sheet.dart';
import '../../widgets/ai_assistant_fab.dart';
import '../../widgets/shell_insets.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final stockAsync = ref.watch(filteredProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.inventory,
        subtitle: l10n.stockAndProducts,
        actions: [
          AiAppBarButton(prompt: l10n.aiInventoryPrompt),
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
            tooltip: l10n.qrShelfLabels,
            onPressed: () => _showBulkQr(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: l10n.allProducts),
            Tab(text: l10n.lowStock),
            Tab(text: l10n.expiring),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppSearchBar(
              hint: l10n.searchProductsHint,
              onChanged: (q) => ref.read(productFilterProvider.notifier).setQuery(q),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ProductList(asyncValue: stockAsync, filterType: 'all'),
                stockAsync.when(
                  loading: () => const ShimmerList(),
                  error: (e, _) => ErrorState(
                    message: e.toString(),
                    title: l10n.somethingWentWrong,
                    retryLabel: l10n.retry,
                  ),
                  data: (products) => _ProductList(
                    asyncValue: AsyncValue.data(products.where((p) => p.isLowStock).toList()),
                    filterType: 'low',
                  ),
                ),
                stockAsync.when(
                  loading: () => const ShimmerList(),
                  error: (e, _) => ErrorState(
                    message: e.toString(),
                    title: l10n.somethingWentWrong,
                    retryLabel: l10n.retry,
                  ),
                  data: (products) => _ProductList(
                    asyncValue: AsyncValue.data(products.where((p) => p.isExpiringSoon || p.isExpired).toList()),
                    filterType: 'expiry',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: ShellFab(
        child: FloatingActionButton.extended(
          onPressed: () => _showAddProductSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.addProduct),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddProductSheet(),
    );
  }

  void _showBulkQr(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(appLocalizationsProvider);
    try {
      final products = await ref.read(productsProvider.future);
      if (!context.mounted) return;
      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noProductsYet)),
        );
        return;
      }
      await showProductQrSheet(context, allProducts: products);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _ProductList extends ConsumerWidget {
  final AsyncValue<List<Product>> asyncValue;
  final String filterType;

  const _ProductList({required this.asyncValue, required this.filterType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    return asyncValue.when(
      loading: () => const ShimmerList(),
      error: (e, _) => ErrorState(
        message: e.toString(),
        title: l10n.somethingWentWrong,
        retryLabel: l10n.retry,
        onRetry: () => ref.invalidate(productsProvider),
      ),
      data: (products) {
        if (products.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_2_outlined,
            title: filterType == 'low' ? l10n.noLowStockItems :
                   filterType == 'expiry' ? l10n.noExpiringItems : l10n.noProductsYet,
            subtitle: filterType == 'all' ? l10n.addFirstProduct : null,
            actionLabel: filterType == 'all' ? l10n.addProduct : null,
            onAction: filterType == 'all' ? () {} : null,
          );
        }
        return ListView.builder(
          padding: ShellInsets.listPadding(context, withFab: true),
          itemCount: products.length,
          itemBuilder: (_, i) => _ProductTile(product: products[i]),
        );
      },
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    Color statusColor;
    String statusLabel;
    if (product.isExpired) {
      statusColor = AppColors.danger; statusLabel = l10n.expired;
    } else if (product.isExpiringSoon) {
      statusColor = AppColors.warning; statusLabel = l10n.expiringBadge;
    } else if (product.isOutOfStock) {
      statusColor = AppColors.danger; statusLabel = l10n.outBadge;
    } else if (product.isLowStock) {
      statusColor = AppColors.warning; statusLabel = l10n.lowStockBadge;
    } else {
      statusColor = AppColors.success; statusLabel = l10n.okBadge;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.white,
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        visualDensity: VisualDensity.compact,
        isThreeLine: product.batchNumber != null || product.expiryDate != null,
        splashColor: primary.withValues(alpha: 0.08),
        hoverColor: primary.withValues(alpha: 0.04),
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.inventory_2_outlined, color: primary, size: 22),
        ),
        title: Text(product.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${product.category} • ${product.sku}',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            if (product.batchNumber != null || product.expiryDate != null)
              Text(
                [
                  if (product.batchNumber != null) l10n.batchLabel(product.batchNumber!),
                  if (product.expiryDate != null) l10n.expLabel(AppFormatters.shortDate(product.expiryDate!)),
                ].join(' • '),
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 88,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppFormatters.tsh(product.price),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text('${product.stock.toStringAsFixed(0)} ${product.unit}',
                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(statusLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.qr_code_rounded, size: 20, color: primary.withValues(alpha: 0.8)),
              onPressed: () => showProductQrSheet(context, product: product),
              tooltip: l10n.showQr,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        onTap: () => _showProductDetail(context, product),
        ),
      ),
    );
  }

  void _showProductDetail(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(product: product),
    );
  }
}

class _ProductDetailSheet extends ConsumerWidget {
  final Product product;
  const _ProductDetailSheet({required this.product});

  Future<void> _adjustStock(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(appLocalizationsProvider);
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: l10n.manualAdjustment);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adjustStock),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.currentStock(product.stock.toStringAsFixed(0), product.unit)),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: l10n.changeQty,
                hintText: 'e.g. 10 or -5',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(labelText: l10n.reason),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.apply)),
        ],
      ),
    );
    if (result != true) {
      qtyCtrl.dispose();
      reasonCtrl.dispose();
      return;
    }
    final delta = double.tryParse(qtyCtrl.text.trim());
    final notes = reasonCtrl.text.trim();
    qtyCtrl.dispose();
    reasonCtrl.dispose();
    if (delta == null || delta == 0) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.adjustStock({
        'product_id': product.id,
        'quantity': delta.abs(),
        'movement_type': delta >= 0 ? 'in' : 'out',
        'notes': notes,
      });
      ref.read(productsRefreshProvider.notifier).state++;
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.stockUpdated), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _editPrice(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(appLocalizationsProvider);
    final priceCtrl = TextEditingController(text: product.price.toStringAsFixed(0));
    final costCtrl = TextEditingController(text: product.cost.toStringAsFixed(0));
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editProduct(product.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.sellingPrice),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.costPrice),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (result != true) {
      priceCtrl.dispose();
      costCtrl.dispose();
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      await api.updateProduct(product.id, {
        'price': double.tryParse(priceCtrl.text) ?? product.price,
        'cost': double.tryParse(costCtrl.text) ?? product.cost,
      });
      priceCtrl.dispose();
      costCtrl.dispose();
      ref.read(productsRefreshProvider.notifier).state++;
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.productUpdated), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      priceCtrl.dispose();
      costCtrl.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.inventory_2_outlined, color: primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(product.category, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(l10n.sku, product.sku),
              _DetailRow(l10n.sellingPrice, AppFormatters.tsh(product.price)),
              _DetailRow(l10n.costPrice, AppFormatters.tsh(product.cost)),
              _DetailRow(l10n.margin, '${product.margin.toStringAsFixed(1)}%'),
              _DetailRow(l10n.stock, '${product.stock.toStringAsFixed(0)} ${product.unit}'),
              _DetailRow(l10n.reorderPoint, '${product.reorderPoint.toStringAsFixed(0)} ${product.unit}'),
              if (product.batchNumber != null) _DetailRow(l10n.batch, product.batchNumber!),
              if (product.expiryDate != null) _DetailRow(l10n.expiry, AppFormatters.date(product.expiryDate!)),
              if (product.supplier != null) _DetailRow(l10n.supplier, product.supplier!),
              if (product.location != null) _DetailRow(l10n.location, product.location!),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showProductQrSheet(context, product: product);
                      },
                      icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                      label: Text(l10n.showQr),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(posPendingProductProvider.notifier).state = product;
                        Navigator.pop(context);
                        context.go('/pos');
                      },
                      icon: const Icon(Icons.point_of_sale_rounded, size: 16),
                      label: Text(l10n.sellInPos),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editPrice(context, ref),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(l10n.edit),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _adjustStock(context, ref),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: Text(l10n.adjustStock),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    ),
  );
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final filter = ref.watch(productFilterProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filterProducts, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.lowStockOnly),
              value: filter.lowStockOnly,
              activeColor: primary,
              onChanged: (_) => ref.read(productFilterProvider.notifier).toggleLowStock(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.expiringItems),
              value: filter.expiringOnly,
              activeColor: primary,
              onChanged: (_) => ref.read(productFilterProvider.notifier).toggleExpiring(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(productFilterProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  child: Text(l10n.reset),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.apply),
                ),
              ),
            ],
          ),
          const SafeArea(top: false, child: SizedBox.shrink()),
        ],
        ),
      ),
    );
  }
}

class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet();

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _skuCtrl   = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl  = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _reorderCtrl = TextEditingController(text: '10');
  final _batchCtrl = TextEditingController();
  String? _selectedCategory;
  String? _selectedUnit;
  DateTime? _expiryDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _skuCtrl.text = ProductCatalog.generateSku();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = ref.read(businessTypeProvider);
      setState(() {
        _selectedCategory = ProductCatalog.defaultCategory(biz);
        _selectedUnit = ProductCatalog.defaultUnit(biz);
      });
    });
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _skuCtrl, _priceCtrl, _costCtrl, _stockCtrl, _reorderCtrl, _batchCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _regenerateSku() => setState(() => _skuCtrl.text = ProductCatalog.generateSku());

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = ref.read(appLocalizationsProvider);
    final biz = ref.read(businessTypeProvider);
    try {
      final api = ref.read(apiClientProvider);
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'sku': _skuCtrl.text.trim().isEmpty ? ProductCatalog.generateSku() : _skuCtrl.text.trim(),
        'category': _selectedCategory ?? ProductCatalog.defaultCategory(biz),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'cost': double.tryParse(_costCtrl.text) ?? 0,
        'stock': double.tryParse(_stockCtrl.text) ?? 0,
        'reorder_point': double.tryParse(_reorderCtrl.text) ?? 10,
        'unit': _selectedUnit ?? ProductCatalog.defaultUnit(biz),
        'business_type': biz,
      };
      if (_batchCtrl.text.trim().isNotEmpty) {
        payload['batch_number'] = _batchCtrl.text.trim();
      }
      if (_expiryDate != null) {
        payload['expiry_date'] = _expiryDate!.toIso8601String();
      }
      final tempId = 'local-prod-${DateTime.now().millisecondsSinceEpoch}';
      final isOnline = ref.read(isOnlineProvider);
      if (isOnline) {
        try {
          await api.createProduct(payload);
          ref.read(isOnlineProvider.notifier).setOnline(true);
          ref.read(productsRefreshProvider.notifier).state++;
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.productAdded), behavior: SnackBarBehavior.floating),
            );
          }
          return;
        } on Exception {
          ref.read(isOnlineProvider.notifier).setOnline(false);
        }
      }
      final sync = OfflineSyncService(ref.read(apiClientProvider));
      await sync.enqueue({
        'entity_type': 'product',
        'entity_id': tempId,
        'action': 'create',
        'payload': payload,
        'client_timestamp': DateTime.now().toIso8601String(),
      });
      ref.read(syncRefreshProvider.notifier).state++;
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(OfflineMessages.mutationQueued(l10n.isSw, 'product')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final biz = ref.watch(businessTypeProvider);
    final categories = ProductCatalog.categoriesFor(biz);
    final units = ProductCatalog.unitsFor(biz);
    final primary = Theme.of(context).colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add_box_outlined, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.addProduct, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(l10n.stockAndProducts, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: l10n.productNameRequired),
                  validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skuCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l10n.sku,
                    helperText: l10n.autoSkuHint,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: l10n.regenerateSku,
                      onPressed: _regenerateSku,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(labelText: l10n.unit),
                      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.reorderPoint),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.sellingPrice, prefixText: 'TSh '),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: _costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.costPrice, prefixText: 'TSh '),
                  )),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.openingStock),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _batchCtrl,
                  decoration: InputDecoration(labelText: l10n.batchNumber),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickExpiry,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.expiry,
                      suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    child: Text(
                      _expiryDate == null
                          ? '—'
                          : AppFormatters.date(_expiryDate!),
                      style: TextStyle(
                        color: _expiryDate == null ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        : Text(l10n.saveProduct),
                  ),
                ),
                const SafeArea(top: false, child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
