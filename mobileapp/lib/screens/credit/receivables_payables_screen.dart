import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/supplier_model.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/suppliers_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/shimmer_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settlement history model (persisted locally)
// ─────────────────────────────────────────────────────────────────────────────
class _SettlementRecord {
  final String partyName;
  final String type;
  final double amount;
  final double balanceAfter;
  final String date;
  final String method;

  const _SettlementRecord({
    required this.partyName,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.date,
    required this.method,
  });

  Map<String, dynamic> toJson() => {
        'partyName': partyName,
        'type': type,
        'amount': amount,
        'balanceAfter': balanceAfter,
        'date': date,
        'method': method,
      };

  factory _SettlementRecord.fromJson(Map<String, dynamic> j) =>
      _SettlementRecord(
        partyName: j['partyName']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
        balanceAfter:
            double.tryParse(j['balanceAfter']?.toString() ?? '0') ?? 0,
        date: j['date']?.toString() ?? '',
        method: j['method']?.toString() ?? '',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ReceivablesPayablesScreen extends ConsumerStatefulWidget {
  const ReceivablesPayablesScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<ReceivablesPayablesScreen> createState() =>
      _ReceivablesPayablesScreenState();
}

class _ReceivablesPayablesScreenState
    extends ConsumerState<ReceivablesPayablesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<_SettlementRecord> _history = [];
  String _searchCustomers = '';
  String _searchSuppliers = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 3,
        vsync: this,
        initialIndex: widget.initialTab.clamp(0, 2));
    _loadHistory();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('dukamkononi_settlements');
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() =>
            _history = list.map(_SettlementRecord.fromJson).toList());
      }
    } catch (_) {}
  }

  Future<void> _appendHistory(_SettlementRecord record) async {
    setState(() => _history = [record, ..._history]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'dukamkononi_settlements',
      jsonEncode(_history.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final access = ref.watch(roleAccessProvider);
    final customersAsync = ref.watch(customersProvider);
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.creditManagement,
        subtitle: l10n.creditManagementSubtitle,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.person_outline_rounded, size: 18),
              text: l10n.tabCustomersDebt,
            ),
            Tab(
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              text: l10n.tabSuppliersDebt,
            ),
            Tab(
              icon: const Icon(Icons.history_rounded, size: 18),
              text: l10n.tabPaymentHistory,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Customers / Receivables ──────────────────────────
          customersAsync.when(
            loading: () => const _LoadingSkeleton(),
            error: (e, _) => _ErrorSliver(
                message: e.toString(), title: l10n.somethingWentWrong,
                retryLabel: l10n.retry,
                onRetry: () =>
                    ref.read(customersRefreshProvider.notifier).state++),
            data: (customers) => _ReceivablesTab(
              customers: customers,
              search: _searchCustomers,
              onSearchChanged: (v) =>
                  setState(() => _searchCustomers = v),
              canSettle: access?.canSettleCustomerDebt ?? false,
              onSettle: (c) => _openCustomerSettlement(context, c),
              l10n: l10n,
            ),
          ),

          // ── Suppliers / Payables ─────────────────────────────
          suppliersAsync.when(
            loading: () => const _LoadingSkeleton(),
            error: (e, _) => _ErrorSliver(
                message: e.toString(), title: l10n.somethingWentWrong,
                retryLabel: l10n.retry,
                onRetry: () =>
                    ref.read(suppliersRefreshProvider.notifier).state++),
            data: (suppliers) => _PayablesTab(
              suppliers: suppliers,
              search: _searchSuppliers,
              onSearchChanged: (v) =>
                  setState(() => _searchSuppliers = v),
              canSettle: access?.canSettleSupplierPayable ?? false,
              onSettle: (s) => _openSupplierSettlement(context, s),
              l10n: l10n,
            ),
          ),

          // ── History ──────────────────────────────────────────
          _HistoryTab(history: _history, l10n: l10n),
        ],
      ),
    );
  }

  void _openCustomerSettlement(BuildContext context, Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerSettlementSheet(
        customer: customer,
        onSaved: _appendHistory,
      ),
    );
  }

  void _openSupplierSettlement(BuildContext context, Supplier supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierSettlementSheet(
        supplier: supplier,
        onSaved: _appendHistory,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          ShimmerBox(width: double.infinity, height: 90, radius: 16),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 48, radius: 12),
          SizedBox(height: 12),
          ShimmerList(count: 4),
        ]),
      );
}

class _ErrorSliver extends StatelessWidget {
  final String message;
  final String title;
  final String? retryLabel;
  final VoidCallback? onRetry;
  const _ErrorSliver(
      {required this.message, required this.title, this.retryLabel, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: ErrorState(
            message: message,
            title: title,
            retryLabel: retryLabel,
            onRetry: onRetry),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Receivables tab — CustomScrollView, no Column+Expanded
// ─────────────────────────────────────────────────────────────────────────────
class _ReceivablesTab extends StatelessWidget {
  const _ReceivablesTab({
    required this.customers,
    required this.search,
    required this.onSearchChanged,
    required this.canSettle,
    required this.onSettle,
    required this.l10n,
  });

  final List<Customer> customers;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final bool canSettle;
  final void Function(Customer) onSettle;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final filtered = customers.where((c) {
      if (search.isEmpty) return c.balance > 0;
      final q = search.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));

    final total = filtered.fold(0.0, (s, c) => s + c.balance);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      slivers: [
        // KPI card
        SliverToBoxAdapter(
          child: _CreditKpiCard(
            totalLabel: l10n.totalReceivables,
            total: total,
            countLabel: l10n.debtorsCount,
            count: filtered.length,
            accent: AppColors.warning,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        // Search bar
        SliverToBoxAdapter(
          child: _SearchBar(
            hint: l10n.searchCustomersHint,
            onChanged: onSearchChanged,
          ),
        ),
        // Permission notice
        if (!canSettle)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(l10n.viewOnlyNoPermission,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ),
        // List or empty state
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.noOutstandingReceivables,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final c = filtered[i];
                  return _PartyDebtCard(
                    partyType: _PartyType.customer,
                    title: c.name,
                    subtitle: c.phone,
                    amount: c.balance,
                    actionLabel: canSettle ? l10n.settleDebt : null,
                    onAction: canSettle ? () => onSettle(c) : null,
                    l10n: l10n,
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payables tab — same pattern
// ─────────────────────────────────────────────────────────────────────────────
class _PayablesTab extends StatelessWidget {
  const _PayablesTab({
    required this.suppliers,
    required this.search,
    required this.onSearchChanged,
    required this.canSettle,
    required this.onSettle,
    required this.l10n,
  });

  final List<Supplier> suppliers;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final bool canSettle;
  final void Function(Supplier) onSettle;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final filtered = suppliers.where((s) {
      if (search.isEmpty) return s.outstandingPayable > 0;
      final q = search.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.outstandingPayable.compareTo(a.outstandingPayable));

    final total =
        filtered.fold(0.0, (s, x) => s + x.outstandingPayable);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: _CreditKpiCard(
            totalLabel: l10n.totalPayables,
            total: total,
            countLabel: l10n.suppliersOwed,
            count: filtered.length,
            accent: AppColors.accentPurple,
            icon: Icons.local_shipping_outlined,
          ),
        ),
        SliverToBoxAdapter(
          child: _SearchBar(
            hint: l10n.searchSuppliersHint,
            onChanged: onSearchChanged,
          ),
        ),
        if (!canSettle)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(l10n.viewOnlyNoPermission,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.local_shipping_outlined,
              title: l10n.noOutstandingPayables,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final s = filtered[i];
                  return _PartyDebtCard(
                    partyType: _PartyType.supplier,
                    title: s.name,
                    subtitle: s.category,
                    amount: s.outstandingPayable,
                    actionLabel: canSettle ? l10n.paySupplier : null,
                    onAction: canSettle ? () => onSettle(s) : null,
                    l10n: l10n,
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History tab
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.history, required this.l10n});
  final List<_SettlementRecord> history;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.history_rounded,
          title: l10n.settlementHistory,
          subtitle: l10n.noData,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final h = history[i];
        final isCustomer = h.type == l10n.receivables;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _PartyTypeBadge(
                  label: isCustomer
                      ? l10n.partyCustomer
                      : l10n.partySupplier,
                  isCustomer: isCustomer,
                ),
                const Spacer(),
                Text(
                  h.date.length >= 10
                      ? h.date.substring(0, 10)
                      : h.date,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint),
                ),
              ]),
              const SizedBox(height: 8),
              Text(h.partyName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(h.method,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppFormatters.tsh(h.amount),
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700)),
                  Text(
                    '${l10n.outstandingBalance}: ${AppFormatters.tsh(h.balanceAfter)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared search bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon:
              const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI card — two-stat banner at top of each tab
// ─────────────────────────────────────────────────────────────────────────────
class _CreditKpiCard extends StatelessWidget {
  const _CreditKpiCard({
    required this.totalLabel,
    required this.total,
    required this.countLabel,
    required this.count,
    required this.accent,
    required this.icon,
  });

  final String totalLabel;
  final double total;
  final String countLabel;
  final int count;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          // Amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(totalLabel,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppFormatters.tsh(total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Count pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1.1,
                  ),
                ),
                Text(
                  countLabel,
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Party debt card
// ─────────────────────────────────────────────────────────────────────────────
enum _PartyType { customer, supplier }

class _PartyDebtCard extends StatelessWidget {
  const _PartyDebtCard({
    required this.partyType,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.l10n,
    this.actionLabel,
    this.onAction,
  });

  final _PartyType partyType;
  final String title;
  final String subtitle;
  final double amount;
  final AppLocalizations l10n;
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get _isCustomer => partyType == _PartyType.customer;
  Color get _accent =>
      _isCustomer ? AppColors.warning : AppColors.accentPurple;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isCustomer
                        ? Icons.person_rounded
                        : Icons.local_shipping_rounded,
                    color: _accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Name + type badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PartyTypeBadge(
                        label: _isCustomer
                            ? l10n.partyCustomer
                            : l10n.partySupplier,
                        isCustomer: _isCustomer,
                      ),
                      const SizedBox(height: 5),
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint)),
                    ],
                  ),
                ),
                // Amount
                Text(
                  AppFormatters.tsh(amount),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _accent,
                      fontSize: 14),
                ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(actionLabel!,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Party type badge
// ─────────────────────────────────────────────────────────────────────────────
class _PartyTypeBadge extends StatelessWidget {
  const _PartyTypeBadge(
      {required this.label, required this.isCustomer});
  final String label;
  final bool isCustomer;

  @override
  Widget build(BuildContext context) {
    final color =
        isCustomer ? AppColors.success : AppColors.accentPurple;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCustomer
                ? Icons.person_outline_rounded
                : Icons.local_shipping_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer settlement sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CustomerSettlementSheet extends ConsumerStatefulWidget {
  const _CustomerSettlementSheet(
      {required this.customer, required this.onSaved});
  final Customer customer;
  final ValueChanged<_SettlementRecord> onSaved;

  @override
  ConsumerState<_CustomerSettlementSheet> createState() =>
      _CustomerSettlementSheetState();
}

class _CustomerSettlementSheetState
    extends ConsumerState<_CustomerSettlementSheet> {
  bool _full = true;
  final _amountCtrl = TextEditingController();
  String _method = 'mpesa';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text =
        widget.customer.balance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = ref.read(appLocalizationsProvider);
    final balanceBefore = widget.customer.balance;
    final amount = _full
        ? balanceBefore
        : (double.tryParse(_amountCtrl.text) ?? 0);
    if (amount <= 0) return;
    final balanceAfter =
        (balanceBefore - amount).clamp(0, double.infinity);

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updateCustomer(widget.customer.id, {
        'balance': balanceAfter,
        'dunning_stage': balanceAfter == 0
            ? 'cleared'
            : widget.customer.dunningStage,
        'loyalty_points': widget.customer.loyaltyPoints +
            (amount / 2000).floor(),
      });
      ref.read(customersRefreshProvider.notifier).state++;
      widget.onSaved(_SettlementRecord(
        partyName: widget.customer.name,
        type: l10n.receivables,
        amount: amount,
        balanceAfter: balanceAfter.toDouble(),
        date: DateTime.now().toIso8601String(),
        method: _method,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.paymentRecorded),
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.errorMessage(e.toString())),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(widget.customer.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${l10n.outstandingBalance}: ${AppFormatters.tsh(widget.customer.balance)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: true, label: Text(l10n.fullPayment)),
                ButtonSegment(
                    value: false,
                    label: Text(l10n.partialPayment)),
              ],
              selected: {_full},
              onSelectionChanged: (s) =>
                  setState(() => _full = s.first),
            ),
            if (!_full) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: l10n.amountToPay,
                    prefixText: 'TSh '),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _method,
              decoration:
                  InputDecoration(labelText: l10n.paymentMethod),
              items: ['mpesa', 'cash', 'bank_transfer', 'tigopesa']
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(l10n.paymentMethodLabel(m))))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _method = v ?? 'mpesa'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(l10n.confirmPayment,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supplier settlement sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SupplierSettlementSheet extends ConsumerStatefulWidget {
  const _SupplierSettlementSheet(
      {required this.supplier, required this.onSaved});
  final Supplier supplier;
  final ValueChanged<_SettlementRecord> onSaved;

  @override
  ConsumerState<_SupplierSettlementSheet> createState() =>
      _SupplierSettlementSheetState();
}

class _SupplierSettlementSheetState
    extends ConsumerState<_SupplierSettlementSheet> {
  bool _full = true;
  final _amountCtrl = TextEditingController();
  String _method = 'bank_transfer';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text =
        widget.supplier.outstandingPayable.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = ref.read(appLocalizationsProvider);
    final balanceBefore = widget.supplier.outstandingPayable;
    final amount = _full
        ? balanceBefore
        : (double.tryParse(_amountCtrl.text) ?? 0);
    if (amount <= 0) return;
    final balanceAfter =
        (balanceBefore - amount).clamp(0, double.infinity);

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updateSupplier(
          widget.supplier.id, {'outstanding_payable': balanceAfter});
      ref.read(suppliersRefreshProvider.notifier).state++;
      widget.onSaved(_SettlementRecord(
        partyName: widget.supplier.name,
        type: l10n.payables,
        amount: amount,
        balanceAfter: balanceAfter.toDouble(),
        date: DateTime.now().toIso8601String(),
        method: _method,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.paymentRecorded),
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.errorMessage(e.toString())),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(widget.supplier.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${l10n.payables}: ${AppFormatters.tsh(widget.supplier.outstandingPayable)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: true, label: Text(l10n.fullPayment)),
                ButtonSegment(
                    value: false,
                    label: Text(l10n.partialPayment)),
              ],
              selected: {_full},
              onSelectionChanged: (s) =>
                  setState(() => _full = s.first),
            ),
            if (!_full) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: l10n.amountToPay,
                    prefixText: 'TSh '),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _method,
              decoration:
                  InputDecoration(labelText: l10n.paymentMethod),
              items: [
                'bank_transfer',
                'cash_drawer',
                'mpesa_till'
              ]
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(l10n.paymentMethodLabel(m))))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _method = v ?? 'bank_transfer'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(l10n.confirmPayment,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
