import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/customer_model.dart';
import '../../providers/customers_provider.dart';
import '../../providers/api_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_widget.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final customersAsync = ref.watch(filteredCustomersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.customers,
        subtitle: l10n.customersSubtitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            onPressed: () => _showAddCustomer(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: l10n.searchCustomersHint,
              onChanged: (q) => ref.read(customerSearchProvider.notifier).setQuery(q),
            ),
          ),
          customersAsync.maybeWhen(
            data: (customers) {
              final withDebt = customers.where((c) => c.hasDebt).length;
              final overdueCount = customers.where((c) => c.isOverdue).length;
              if (customers.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(child: _SummaryChip(l10n.summaryTotal, '${customers.length}', AppColors.primary)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryChip(l10n.withDebt, '$withDebt', AppColors.warning)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryChip(l10n.overdue, '$overdueCount', AppColors.danger)),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: customersAsync.when(
              loading: () => const ShimmerList(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                title: l10n.somethingWentWrong,
                retryLabel: l10n.retry,
              ),
              data: (customers) {
                if (customers.isEmpty) return EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: l10n.noCustomers,
                  subtitle: l10n.addFirstCustomer,
                );
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: customers.length,
                  itemBuilder: (_, i) => _CustomerTile(customer: customers[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCustomerSheet(),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    ),
  );
}

class _CustomerTile extends ConsumerWidget {
  final Customer customer;
  const _CustomerTile({required this.customer});

  Color get _tierColor {
    switch (customer.loyaltyTier) {
      case LoyaltyTier.gold:   return const Color(0xFFFFD700);
      case LoyaltyTier.silver: return const Color(0xFFC0C0C0);
      default:                 return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context, customer),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: customer.isOverdue
                  ? AppColors.danger.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Text(
                    customer.initials,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.circle, size: 8, color: _tierColor),
                          const SizedBox(width: 4),
                          Text(
                            loyaltyTierLabel(customer.loyaltyTier),
                            style: TextStyle(
                              fontSize: 9,
                              color: _tierColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (customer.hasDebt) ...[
                      Text(
                        l10n.owesAmount(AppFormatters.tsh(customer.balance)),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (customer.isOverdue)
                        Text(
                          l10n.daysOverdue(customer.daysOverdue),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.danger,
                          ),
                        ),
                    ] else
                      Text(
                        l10n.noDebt,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                        ),
                      ),
                    Text(
                      l10n.pointsCount(customer.loyaltyPoints),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  void _showDetail(BuildContext context, Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerDetailSheet(customer: customer),
    );
  }
}

class _CustomerDetailSheet extends ConsumerWidget {
  final Customer customer;
  const _CustomerDetailSheet({required this.customer});

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
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primary.withValues(alpha: 0.15),
                    child: Text(customer.initials,
                      style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 20)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(customer.phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (customer.hasDebt) Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.dangerGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.outstandingBalance, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(AppFormatters.tsh(customer.balance),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l10n.creditLimit, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(AppFormatters.tsh(customer.creditLimit),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(l10n.email, customer.email.isEmpty ? '—' : customer.email),
              _InfoRow(l10n.address, customer.address.isEmpty ? '—' : customer.address),
              _InfoRow(l10n.loyaltyTier, loyaltyTierLabel(customer.loyaltyTier)),
              _InfoRow(l10n.points, '${customer.loyaltyPoints}'),
              _InfoRow(l10n.totalPurchases, AppFormatters.tsh(customer.totalPurchases)),
              if (customer.lastPurchaseDate != null)
                _InfoRow(l10n.lastPurchase, AppFormatters.date(customer.lastPurchaseDate!)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.totalPurchasesAmount(AppFormatters.tsh(customer.totalPurchases)),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: Text(l10n.purchases),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: customer.hasDebt ? () {
                      Navigator.pop(context);
                      context.go('/credit');
                    } : null,
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: Text(l10n.recordPayment),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _AddCustomerSheet extends ConsumerStatefulWidget {
  const _AddCustomerSheet();

  @override
  ConsumerState<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<_AddCustomerSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _emailCtrl  = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _emailCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.createCustomer({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      ref.read(customersRefreshProvider.notifier).state++;
      if (mounted) {
        final l10n = ref.read(appLocalizationsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.customerAdded),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = ref.read(appLocalizationsProvider);
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
    return DraggableScrollableSheet(
    initialChildSize: 0.6,
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
              Text(l10n.addCustomer, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextFormField(controller: _nameCtrl,
                decoration: InputDecoration(labelText: l10n.fullNameRequired,
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20)),
                validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phoneRequired,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20)),
                validator: (v) => (v == null || v.length < 10) ? l10n.enterValidPhone : null),
              const SizedBox(height: 12),
              TextFormField(controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.emailOptional,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      : Text(l10n.saveCustomer),
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
