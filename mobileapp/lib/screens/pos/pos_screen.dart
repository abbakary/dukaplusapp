import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product_model.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/product_qr.dart';
import '../../providers/cart_provider.dart';
import '../../providers/business_settings_provider.dart';
import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/bi_provider.dart';
import '../../providers/pos_resume_provider.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_provider.dart';
import '../../widgets/qr_scanner_sheet.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/drawer_menu_button.dart';
import '../../widgets/stipend_claim_banner.dart';
import '../../widgets/ai_assistant_fab.dart';

Future<void> _openPaymentSheet(BuildContext context) async {
  final sale = await showModalBottomSheet<SaleTransaction?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => const _PaymentSheet(),
  );
  if (sale != null && context.mounted) {
    _showSaleSuccessDialog(context, sale);
  }
}

void _showSaleSuccessDialog(BuildContext context, SaleTransaction sale) {
  final l10n = ProviderScope.containerOf(context).read(appLocalizationsProvider);
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.saleComplete,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.receiptNumber(sale.receiptNumber),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.tsh(sale.total),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.close),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${l10n.receiptNumber(sale.receiptNumber)} — ${AppFormatters.tsh(sale.total)}',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          },
          icon: const Icon(Icons.receipt_long_rounded, size: 15),
          label: Text(l10n.print, style: const TextStyle(fontSize: 13)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// POS Screen
// ─────────────────────────────────────────────────────────────────────────────
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});
  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String? _activeDraftId;
  bool _resumeApplied = false;
  Timer? _searchDebounce;
  Timer? _autosaveDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyResumeIfNeeded();
      _applyPendingProduct();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _autosaveDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyResumeIfNeeded() {
    final resume = ref.read(posResumeProvider);
    if (resume.initialCart == null || resume.initialCart!.items.isEmpty) return;
    ref.read(cartProvider.notifier).loadState(resume.initialCart!);
    _activeDraftId = resume.resumeDraftId;
    ref.read(activePosDraftIdProvider.notifier).state = resume.resumeDraftId;
    _resumeApplied = true;
    if (!mounted) return;
    final l10n = ref.read(appLocalizationsProvider);
    final customer = resume.initialCart!.customerName;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          customer != null
              ? l10n.restoredForCustomer(customer)
              : resume.resumeSaleId != null
                  ? l10n.pendingSaleLoaded
                  : l10n.draftRestored,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyPendingProduct() {
    final pending = ref.read(posPendingProductProvider);
    if (pending == null) return;
    ref.read(cartProvider.notifier).addItem(pending);
    ref.read(posPendingProductProvider.notifier).state = null;
    if (!mounted) return;
    final l10n = ref.read(appLocalizationsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addedProduct(pending.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _autosaveDraft(CartState cart) async {
    if (cart.isEmpty) return;
    final user = ref.read(currentUserProvider);
    final tenantId = user?.businessId ?? user?.id ?? 'default';
    final svc = ref.read(openTransactionServiceProvider);
    final draft = svc.draftFromCart(
      cart,
      id: _activeDraftId,
      status: 'open',
    );
    _activeDraftId = draft.id;
    ref.read(activePosDraftIdProvider.notifier).state = draft.id;
    await svc.upsert(tenantId, draft);
    ref.read(openDraftsRefreshProvider.notifier).state++;
  }

  List<String> _categories(List<Product> products, AppLocalizations l10n) {
    final cats = products.map((p) => p.category).toSet().toList()..sort();
    return [l10n.allCategories, ...cats];
  }

  bool _isAllCategory(String label, AppLocalizations l10n) =>
      label == l10n.allCategories || label == 'All';

  List<Product> _filter(List<Product> products, AppLocalizations l10n) {
    final q = _searchQuery.toLowerCase();
    return products.where((p) {
      final matchQ = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      final matchCat =
          _isAllCategory(_selectedCategory, l10n) || p.category == _selectedCategory;
      return matchQ && matchCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    ref.listen<PosResumeState>(posResumeProvider, (prev, next) {
      if (next.initialCart != null &&
          next.initialCart!.items.isNotEmpty &&
          (!_resumeApplied || prev?.initialCart != next.initialCart)) {
        ref.read(cartProvider.notifier).loadState(next.initialCart!);
        _activeDraftId = next.resumeDraftId;
        ref.read(activePosDraftIdProvider.notifier).state = next.resumeDraftId;
        _resumeApplied = true;
      }
    });

    ref.listen<CartState>(cartProvider, (prev, next) {
      final resume = ref.read(posResumeProvider);
      if (resume.resumeSaleId != null) return;
      if (!next.isEmpty) {
        _autosaveDebounce?.cancel();
        _autosaveDebounce = Timer(const Duration(milliseconds: 500), () {
          if (mounted) _autosaveDraft(next);
        });
      }
    });

    final bizType       = ref.watch(businessTypeProvider);
    final showCartBar     = ref.watch(cartProvider.select((c) => !c.isEmpty));
    final primary       = AppColors.forBusiness(bizType);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _PosAppBar(bizType: bizType, cartCount: ref.watch(cartProvider.select((c) => c.itemCount))),
      body: Column(
        children: [
          const StipendClaimBanner(),
          // ── Search bar ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: AppSearchBar(
              controller: _searchCtrl,
              hint: l10n.searchProductHint,
              onChanged: (v) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _searchQuery = v);
                });
              },
            ),
          ),

          // ── Category chips ───────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: productsAsync.maybeWhen(
              data: (products) {
                final cats = _categories(products, l10n);
                return SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: cats.length,
                    itemBuilder: (_, i) {
                      final sel = cats[i] == _selectedCategory ||
                          (_isAllCategory(cats[i], l10n) && _isAllCategory(_selectedCategory, l10n));
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cats[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel ? primary : primary.withAlpha(18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(cats[i],
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : primary)),
                        ),
                      );
                    },
                  ),
                );
              },
              orElse: () => const SizedBox(height: 32),
            ),
          ),

          // ── Product grid ─────────────────────────────────────────
          Expanded(
            child: productsAsync.when(
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: _delegate(),
                itemCount: 9,
                itemBuilder: (_, __) => const ShimmerBox(
                    width: double.infinity, height: 120, radius: 12),
              ),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 40, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text(l10n.couldNotLoadProducts,
                          style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(productsProvider),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (products) {
                final filtered = _filter(products, l10n);
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 40, color: primary.withAlpha(70)),
                          const SizedBox(height: 10),
                          Text(
                            _searchQuery.isNotEmpty
                                ? l10n.noResultsFor(_searchQuery)
                                : l10n.noProductsInCategory,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _buildGrid(filtered, primary);
              },
            ),
          ),

          // ── Cart summary bar (compact) ────────────────────────────
          if (showCartBar) _CartBar(primary: primary),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Product> products, Color primary) =>
      GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: _delegate(),
        itemCount: products.length,
        itemBuilder: (_, i) => _ProductCard(
          product: products[i],
          primary: primary,
          onTap: () =>
              ref.read(cartProvider.notifier).addItem(products[i]),
        ),
      );

  // 3 columns, compact aspect ratio
  SliverGridDelegateWithFixedCrossAxisCount _delegate() =>
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// POS AppBar
// ─────────────────────────────────────────────────────────────────────────────
class _PosAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String bizType;
  final int cartCount;
  const _PosAppBar({required this.bizType, required this.cartCount});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    return Container(
      decoration:
          BoxDecoration(gradient: AppColors.gradientForBusiness(bizType)),
      child: SafeArea(
        bottom: false,
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: const DrawerMenuButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.pointOfSale,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              Text(
                ref.watch(authProvider).user?.businessName ?? '',
                style:
                    TextStyle(color: Colors.white.withAlpha(200), fontSize: 11),
              ),
            ],
          ),
          actions: [
            AiAppBarButton(),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 22),
              onPressed: () => _scanOrLookupProduct(context, ref),
            ),
            _CartIconButton(cartCount: cartCount),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  final int cartCount;
  const _CartIconButton({required this.cartCount});

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined,
                color: Colors.white, size: 22),
            onPressed: () => _showCart(context),
          ),
          if (cartCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: AppColors.accentRed, shape: BoxShape.circle),
                constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text('$cartCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center),
              ),
            ),
        ],
      );

  void _showCart(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => const _CartSheet(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Card — compact 3-column version
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final Product product;
  final Color primary;
  final VoidCallback onTap;

  const _ProductCard(
      {required this.product, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final isOos = product.isOutOfStock;
    return GestureDetector(
      onTap: isOos ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: product.isLowStock && !isOos
                ? AppColors.warning.withAlpha(150)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Stack(
          children: [
            // ── Content ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small icon
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        color: primary, size: 18),
                  ),
                  const SizedBox(height: 6),
                  // Name
                  Expanded(
                    child: Text(product.name,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 4),
                  // Price
                  Text(
                    AppFormatters.compact(product.price),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primary),
                  ),
                  // Stock
                  Text(
                    '${product.stock.toStringAsFixed(0)} ${product.unit}',
                    style: TextStyle(
                        fontSize: 9,
                        color: product.isLowStock
                            ? AppColors.warning
                            : AppColors.textHint),
                  ),
                ],
              ),
            ),

            // ── Out-of-stock overlay ──────────────────────────
            if (isOos)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(90),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(l10n.outOfStock.replaceAll(' ', '\n'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1.3)),
              ),

            // ── LOW badge ────────────────────────────────────
            if (product.isLowStock && !isOos)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(l10n.lowStockBadge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800)),
                ),
              ),

            // ── Add button (bottom-right) ─────────────────────
            if (!isOos)
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        color: primary, shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact Cart Bar (shown at bottom when cart has items)
// ─────────────────────────────────────────────────────────────────────────────
class _CartBar extends ConsumerWidget {
  final Color primary;
  const _CartBar({required this.primary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totals = ref.watch(cartTotalsProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cart icon + count
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.shopping_cart_rounded, color: primary, size: 20),
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                          color: primary, shape: BoxShape.circle),
                      child: Text('${cart.itemCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Totals
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.itemCount(cart.itemCount),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                  Text(AppFormatters.tsh(totals.total),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: primary)),
                ],
              ),
            ),
            // View + Pay buttons
            OutlinedButton(
              onPressed: () => _openCart(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(color: primary),
              ),
              child:
                  Text(l10n.view, style: TextStyle(fontSize: 12, color: primary)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _openPaymentSheet(context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.pay, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _openCart(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => const _CartSheet(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart Sheet — fixed height, no overflow
// ─────────────────────────────────────────────────────────────────────────────
class _CartSheet extends ConsumerWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final cart    = ref.watch(cartProvider);
    final totals  = ref.watch(cartTotalsProvider);
    final settings = ref.watch(businessSettingsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final mq      = MediaQuery.of(context);
    final compact = mq.size.height < 560;
    final sheetH  = (mq.size.height * (compact ? 0.88 : 0.72))
        .clamp(280.0, mq.size.height * 0.92);

    return Container(
      height: sheetH,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Handle ────────────────────────────────────────
          const _Handle(),
          // ── Header ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(18, compact ? 6 : 10, 18, compact ? 4 : 6),
            child: Row(
              children: [
                Text(l10n.orderSummary,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (!cart.isEmpty)
                  GestureDetector(
                    onTap: () => ref.read(cartProvider.notifier).clear(),
                    child: Text(l10n.clearAll,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Items list ────────────────────────────────────
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_cart_outlined,
                            size: 44, color: AppColors.textHint),
                        const SizedBox(height: 10),
                        Text(l10n.cartEmpty,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) =>
                        _CartItemRow(item: cart.items[i]),
                  ),
          ),

          if (!cart.isEmpty)
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    // ── Totals ─────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(18, compact ? 8 : 10, 18, compact ? 4 : 6),
                      child: Column(
                        children: [
                          if (settings.discountEnabled &&
                              settings.showDiscountOnReceipts &&
                              totals.discountAmount > 0) ...[
                            _TRow(l10n.grossSubtotal, AppFormatters.tsh(totals.grossSubtotal)),
                            _TRow(l10n.discount, '- ${AppFormatters.tsh(totals.discountAmount)}',
                                valueColor: AppColors.warning),
                          ],
                          _TRow(l10n.subtotal, AppFormatters.tsh(totals.subtotal)),
                          const SizedBox(height: 3),
                          _TRow(l10n.vat18, AppFormatters.tsh(totals.vatAmount)),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
                            child: const Divider(height: 1),
                          ),
                          _TRow(
                            l10n.total,
                            AppFormatters.tsh(totals.total),
                            bold: true,
                            valueColor: primary,
                            fontSize: compact ? 14 : 15,
                          ),
                        ],
                      ),
                    ),
                    // ── Actions ────────────────────────────────────
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, compact ? 8 : 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showCustomerPicker(context, ref),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: Icon(Icons.person_add_outlined, size: compact ? 14 : 16),
                                    label: Text(
                                      cart.hasCustomer
                                          ? cart.customerName!
                                          : l10n.genericCustomer,
                                      style: TextStyle(fontSize: compact ? 11 : 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _openPaymentSheet(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: Icon(Icons.payment_rounded, size: compact ? 14 : 16),
                                    label: Text(l10n.payNow,
                                        style: TextStyle(fontSize: compact ? 11 : 12)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: compact ? 6 : 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _saveAndNext(context, ref),
                                icon: Icon(Icons.save_outlined, size: compact ? 14 : 16),
                                label: Text(l10n.saveAndNext,
                                    style: TextStyle(fontSize: compact ? 11 : 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart Item Row
// ─────────────────────────────────────────────────────────────────────────────
class _CartItemRow extends ConsumerWidget {
  final CartItem item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final settings = ref.watch(businessSettingsProvider);
    final primary  = Theme.of(context).colorScheme.primary;
    final l10n     = ref.watch(appLocalizationsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
          // Icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: primary.withAlpha(22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: primary, size: 18),
          ),
          const SizedBox(width: 10),
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(AppFormatters.tsh(item.product.price),
                    style:
                        TextStyle(fontSize: 11, color: primary)),
              ],
            ),
          ),
          // Qty controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QBtn(
                icon: Icons.remove_rounded,
                color: AppColors.danger,
                onTap: () => notifier.updateQty(
                    item.product.id, item.quantity - 1),
              ),
              SizedBox(
                width: 30,
                child: Text('${item.quantity.toInt()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              _QBtn(
                icon: Icons.add_rounded,
                color: AppColors.success,
                onTap: () => notifier.updateQty(
                    item.product.id, item.quantity + 1),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Line total
          SizedBox(
            width: 68,
            child: Text(
                AppFormatters.tsh(settings.discountEnabled ? item.lineTotal : item.originalTotal),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ),
            ],
          ),
          if (settings.discountEnabled) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(l10n.discountPercent,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                const Spacer(),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final pct in ([0, 5, 10, settings.maxDiscountPercent.round()]
                          ..sort()))
                      ChoiceChip(
                        label: Text('$pct%', style: const TextStyle(fontSize: 10)),
                        selected: item.discountPercent.round() == pct,
                        onSelected: (_) => notifier.updateDiscount(
                          item.product.id,
                          settings.capDiscount(pct.toDouble()),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: color.withAlpha(22),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      );
}

class _TRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final double fontSize;

  const _TRow(this.label, this.value,
      {this.bold = false, this.valueColor, this.fontSize = 13});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  color: bold
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight:
                      bold ? FontWeight.w800 : FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Sheet — fixed height, no overflow
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet();

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  String _method   = 'cash';
  final _amtCtrl   = TextEditingController();
  bool _completing = false;

  @override
  void dispose() {
    _amtCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeSale() async {
    final cart = ref.read(cartProvider);
    final totals = ref.read(cartTotalsProvider);
    final user = ref.read(currentUserProvider);
    final l10n = ref.read(appLocalizationsProvider);
    if (user == null || cart.isEmpty) return;

    setState(() => _completing = true);
    try {
      final tendered =
          double.tryParse(_amtCtrl.text.replaceAll(',', '')) ??
              totals.total;
      final resume = ref.read(posResumeProvider);
      SaleTransaction? completedSale;

      if (resume.resumeSaleId != null) {
        final api = ref.read(apiClientProvider);
        final raw = await api.finalizeSale(resume.resumeSaleId!, {
          'payments': [
            {'method': _method, 'amount': tendered}
          ],
          if (cart.customerId != null) 'customer_id': cart.customerId,
          if (cart.customerName != null) 'customer_name': cart.customerName,
        });
        completedSale = SaleTransaction.fromJson(
          Map<String, dynamic>.from(raw as Map),
        );
      } else {
        completedSale = await ref.read(completeSaleProvider.notifier).execute(
              CompleteSaleParams(
                cart: cart,
                payments: [
                  {'method': _method, 'amount': tendered}
                ],
                type: SaleType.full,
                cashier: user,
              ),
            );
      }

      if (completedSale == null) {
        throw Exception(l10n.saleNotRecorded);
      }

      final tenantId = user.businessId ?? user.id;
      final draftId = ref.read(activePosDraftIdProvider);
      if (draftId != null) {
        await ref.read(openTransactionServiceProvider).remove(tenantId, draftId);
        ref.read(activePosDraftIdProvider.notifier).state = null;
        ref.read(openDraftsRefreshProvider.notifier).state++;
      }
      ref.read(posResumeProvider.notifier).clear();
      ref.read(cartProvider.notifier).clear();
      ref.read(salesRefreshProvider.notifier).state++;

      if (mounted) {
        Navigator.pop(context, completedSale);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.errorMessage(e.toString())),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _completing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final cart    = ref.watch(cartProvider);
    final totals  = ref.watch(cartTotalsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final mq      = MediaQuery.of(context);
    final tendered =
        double.tryParse(_amtCtrl.text.replaceAll(',', '')) ?? totals.total;
    final change   = tendered - totals.total;

    return Container(
      // Fixed height — no overflow
      height: mq.size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const _Handle(),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.payment,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(AppFormatters.tsh(totals.total),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: primary)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Payment method grid ─────────────────
                  Text(l10n.paymentMethod,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 7,
                    crossAxisSpacing: 7,
                    childAspectRatio: 1.7,
                    physics: const NeverScrollableScrollPhysics(),
                    children: AppConstants.paymentMethods.map((m) {
                      final sel = _method == m['id'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _method = m['id']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          decoration: BoxDecoration(
                            color: sel
                                ? primary.withAlpha(22)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? primary : AppColors.border,
                              width: sel ? 1.8 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(m['icon']!,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(l10n.paymentMethodLabel(m['id']!),
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? primary
                                          : AppColors.textSecondary),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // ── Amount ──────────────────────────────
                  Text(l10n.amountTendered,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amtCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: AppFormatters.tsh(totals.total),
                      prefixText: 'TSh ',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),

                  // ── Change ──────────────────────────────
                  if (_amtCtrl.text.isNotEmpty && change >= 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.success.withAlpha(70)),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.changeDue,
                              style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(AppFormatters.tsh(change),
                              style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // ── Fixed bottom button ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _completing ? null : _completeSale,
                icon: _completing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline_rounded,
                        size: 18),
                label: Text(
                    _completing ? l10n.processing : l10n.completeSale,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POS helpers — customer picker, barcode lookup, save & next
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _scanOrLookupProduct(BuildContext context, WidgetRef ref) async {
  final code = await showQrScanner(context);
  if (code != null && code.isNotEmpty) {
    await _addProductByCode(context, ref, code);
    return;
  }
  await _showBarcodeLookup(context, ref);
}

Future<void> _addProductByCode(
  BuildContext context,
  WidgetRef ref,
  String code,
) async {
  final l10n = ref.read(appLocalizationsProvider);
  try {
    final products = await ref.read(productsProvider.future);
    final parsed = parseScannedQrPayload(code);
    Product? match;

    if (parsed != null) {
      if (parsed.id.isNotEmpty) {
        for (final p in products) {
          if (p.id == parsed.id) {
            match = p;
            break;
          }
        }
      }
      if (match == null && parsed.sku.isNotEmpty) {
        final sku = parsed.sku.toLowerCase();
        for (final p in products) {
          if (p.sku.toLowerCase() == sku) {
            match = p;
            break;
          }
        }
      }
    }

    if (match == null) {
      final q = code.toLowerCase();
      for (final p in products) {
        if (p.sku.toLowerCase() == q || p.name.toLowerCase().contains(q)) {
          match = p;
          break;
        }
      }
    }

    if (match == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noProductFoundFor(code))),
        );
      }
      return;
    }
    ref.read(cartProvider.notifier).addItem(match);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addedProduct(match.name)),
          behavior: SnackBarBehavior.floating,
        ),
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

Future<void> _showBarcodeLookup(BuildContext context, WidgetRef ref) async {
  final l10n = ref.read(appLocalizationsProvider);
  final ctrl = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.scanCode),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.barcodeSku,
          hintText: l10n.typeOrScanCode,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text(l10n.find),
        ),
      ],
    ),
  );
  ctrl.dispose();
  if (code == null || code.isEmpty || !context.mounted) return;
  await _addProductByCode(context, ref, code);
}

Future<void> _showCustomerPicker(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CustomerPickerSheet(),
  );
}

Future<void> _saveAndNext(BuildContext context, WidgetRef ref) async {
  final cart = ref.read(cartProvider);
  final user = ref.read(currentUserProvider);
  final l10n = ref.read(appLocalizationsProvider);
  if (user == null || cart.isEmpty) return;

  try {
    await ref.read(completeSaleProvider.notifier).execute(
          CompleteSaleParams(
            cart: cart,
            payments: [],
            type: SaleType.full,
            cashier: user,
            finalize: false,
          ),
        );

    final tenantId = user.businessId ?? user.id;
    final draftId = ref.read(activePosDraftIdProvider);
    if (draftId != null) {
      await ref.read(openTransactionServiceProvider).remove(tenantId, draftId);
      ref.read(activePosDraftIdProvider.notifier).state = null;
    }
    ref.read(posResumeProvider.notifier).clear();
    ref.read(cartProvider.notifier).clear();
    ref.read(salesRefreshProvider.notifier).state++;
    ref.read(openDraftsRefreshProvider.notifier).state++;

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saleSaved),
          behavior: SnackBarBehavior.floating,
        ),
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

class _CustomerPickerSheet extends ConsumerWidget {
  const _CustomerPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final customersAsync = ref.watch(customersProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const _Handle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  Text(l10n.selectCustomer,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).clearCustomer();
                      Navigator.pop(context);
                    },
                    child: Text(l10n.walkIn),
                  ),
                ],
              ),
            ),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(l10n.errorMessage(e.toString()))),
                data: (customers) => ListView.separated(
                  controller: ctrl,
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = customers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary.withOpacity(0.12),
                        child: Text(c.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(c.phone),
                      onTap: () {
                        ref.read(cartProvider.notifier).setCustomer(c.id, c.name);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────
class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
}
