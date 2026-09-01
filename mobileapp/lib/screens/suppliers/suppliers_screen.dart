import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/supplier_model.dart';
import '../../providers/suppliers_provider.dart';
import '../../providers/api_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/shell_insets.dart';

final _supplierSearchProvider = StateProvider<String>((ref) => '');

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final search = ref.watch(_supplierSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.suppliers,
        subtitle: l10n.procurementPayables,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => _showAddSupplier(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: l10n.searchSuppliersHint,
              onChanged: (q) => ref.read(_supplierSearchProvider.notifier).state = q,
            ),
          ),
          Expanded(
            child: suppliersAsync.when(
              loading: () => const ShimmerList(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                title: l10n.somethingWentWrong,
                retryLabel: l10n.retry,
              ),
              data: (suppliers) {
                final filtered = search.isEmpty ? suppliers
                    : suppliers.where((s) => s.name.toLowerCase().contains(search.toLowerCase())).toList();
                if (filtered.isEmpty) return EmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: l10n.noSuppliersYet,
                  subtitle: l10n.addFirstSupplier,
                );
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppColors.warningGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.totalPayables, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text(
                                AppFormatters.tsh(filtered.fold(0.0, (s, sup) => s + sup.outstandingPayable)),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(l10n.suppliers, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text('${filtered.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _SupplierTile(supplier: filtered[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ShellFab(
        child: FloatingActionButton.extended(
          onPressed: () => _showCreatePO(context),
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: Text(l10n.createPO),
        ),
      ),
    );
  }

  void _showAddSupplier(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddSupplierSheet(),
    );
  }

  void _showCreatePO(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePOSheet(),
    );
  }
}

class _SupplierTile extends ConsumerWidget {
  final Supplier supplier;
  const _SupplierTile({required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: supplier.outstandingPayable > 0 ? AppColors.warning.withOpacity(0.4) : AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.white,
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        splashColor: primary.withOpacity(0.08),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: primary.withOpacity(0.15),
          child: Text(supplier.initials,
            style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
        title: Text(supplier.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${supplier.contactPerson} • ${supplier.paymentTerms}',
          style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (supplier.outstandingPayable > 0)
              Text(AppFormatters.tsh(supplier.outstandingPayable),
                style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600))
            else
              Text(l10n.paidUp, style: const TextStyle(fontSize: 11, color: AppColors.success)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) => Icon(
                i < supplier.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 12, color: AppColors.accentOrange,
              )),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _AddSupplierSheet extends ConsumerStatefulWidget {
  const _AddSupplierSheet();

  @override
  ConsumerState<_AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends ConsumerState<_AddSupplierSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _contactCtrl, _phoneCtrl]) c.dispose();
    super.dispose();
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
              Text(l10n.addSupplier, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextFormField(controller: _nameCtrl,
                decoration: InputDecoration(labelText: l10n.companyNameRequired),
                validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
              const SizedBox(height: 12),
              TextFormField(controller: _contactCtrl,
                decoration: InputDecoration(labelText: l10n.contactPerson)),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phoneRequired),
                validator: (v) => (v == null || v.length < 10) ? l10n.requiredField : null),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _saving = true);
                    try {
                      final api = ref.read(apiClientProvider);
                      await api.createSupplier({
                        'name': _nameCtrl.text.trim(),
                        'contact_person': _contactCtrl.text.trim(),
                        'phone': _phoneCtrl.text.trim(),
                      });
                      ref.read(suppliersRefreshProvider.notifier).state++;
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.supplierAdded),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.errorMessage(e.toString())),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
                  child: _saving
                      ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      : Text(l10n.saveSupplier),
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

class _CreatePOSheet extends ConsumerWidget {
  const _CreatePOSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    return Container(
    height: MediaQuery.of(context).size.height * 0.75,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 16),
        Text(l10n.createPurchaseOrder, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(l10n.createPOHint,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(l10n.sendPurchaseOrder),
          ),
        ),
        const SafeArea(top: false, child: SizedBox.shrink()),
      ],
    ),
  );
  }
}
