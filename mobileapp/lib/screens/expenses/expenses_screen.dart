import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/payroll_store.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/api_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  PayrollStoreData _payroll = const PayrollStoreData();
  bool _payrollLoaded = false;
  String _selectedMonth = PayrollStore.currentMonthStr();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
    _tabs.addListener(() => setState(() {}));
    _loadPayroll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadPayroll() async {
    final user = ref.read(currentUserProvider);
    final tenantId = user?.id ?? 'local';
    final data = await PayrollStore.load(tenantId);
    if (mounted) setState(() { _payroll = data; _payrollLoaded = true; });
  }

  Future<void> _savePayroll() async {
    final user = ref.read(currentUserProvider);
    final tenantId = user?.id ?? 'local';
    await PayrollStore.save(tenantId, _payroll);
  }

  StaffPayrollConfig _ratesFor(StaffMember staff) {
    final cfg = _payroll.staffConfig[staff.id];
    return cfg ?? const StaffPayrollConfig(
      baseSalary: 450000,
      dailyFoodAllowance: 5000,
      dailyTransportAllowance: 3000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final access = ref.watch(roleAccessProvider);
    final canManage = access?.canManageExpenses ?? false;
    final canPayroll = access?.canManagePayroll ?? false;
    final canAllowances = access?.canConfigureAllowances ?? false;

    if (access != null && !access.canSeeExpenses) {
      return Scaffold(
        body: Center(child: Text(l10n.noPermissionPayroll)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.expensesPayroll,
        subtitle: l10n.costTrackingSubtitle,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: l10n.opexLedger),
            Tab(text: '${l10n.dailyStipends}\n${l10n.todayLabel}'),
            Tab(text: l10n.monthlyPayroll),
          ],
        ),
      ),
      body: !_payrollLoaded
          ? const ShimmerList()
          : TabBarView(
              controller: _tabs,
              children: [
                _OpexTab(canManage: canManage, l10n: l10n, onAdd: () => _showAddExpense(context)),
                _AllowancesTab(
                  l10n: l10n,
                  canConfigure: canAllowances,
                  canManageExpenses: canManage,
                  payroll: _payroll,
                  onUpdated: (data) async {
                    setState(() => _payroll = data);
                    await _savePayroll();
                    ref.read(expensesRefreshProvider.notifier).state++;
                  },
                  ratesFor: _ratesFor,
                ),
                _PayrollTab(
                  l10n: l10n,
                  canPayroll: canPayroll,
                  canManageExpenses: canManage,
                  payroll: _payroll,
                  selectedMonth: _selectedMonth,
                  onMonthChanged: (m) => setState(() => _selectedMonth = m),
                  onUpdated: (data) async {
                    setState(() => _payroll = data);
                    await _savePayroll();
                    ref.read(expensesRefreshProvider.notifier).state++;
                  },
                  ratesFor: _ratesFor,
                ),
              ],
            ),
      floatingActionButton: _tabs.index == 0 && canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExpense(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addExpense),
              backgroundColor: AppColors.danger,
            )
          : null,
    );
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddExpenseSheet(),
    );
  }
}

class _OpexTab extends ConsumerWidget {
  const _OpexTab({required this.canManage, required this.l10n, required this.onAdd});
  final bool canManage;
  final dynamic l10n;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    return expensesAsync.when(
      loading: () => const ShimmerList(),
      error: (e, _) => ErrorState(message: e.toString(), title: l10n.somethingWentWrong, retryLabel: l10n.retry),
      data: (expenses) {
        final opex = expenses.where((e) =>
          e.category != 'daily_stipends_food_transport' && e.category != 'staff_salaries').toList();
        final total = opex.fold(0.0, (s, e) => s + e.amount);
        return Column(
          children: [
            _SummaryCard(total: total, count: opex.length, l10n: l10n),
            if (!canManage)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.viewOnlyNoPermission, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            Expanded(
              child: opex.isEmpty
                  ? EmptyState(icon: Icons.receipt_outlined, title: l10n.noExpensesRecorded, subtitle: l10n.startRecordingExpenses)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: opex.length,
                      itemBuilder: (_, i) => _ExpenseTile(
                        expense: opex[i],
                        canManage: canManage,
                        onEdit: () => _showEdit(context, opex[i]),
                        onDelete: () => _delete(context, ref, opex[i].id),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showEdit(BuildContext context, ExpenseItem expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseSheet(existing: expense),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final l10n = ref.read(appLocalizationsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteExpense),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(apiClientProvider).deleteExpense(id);
    ref.read(expensesRefreshProvider.notifier).state++;
  }
}

class _AllowancesTab extends ConsumerWidget {
  const _AllowancesTab({
    required this.l10n,
    required this.canConfigure,
    required this.canManageExpenses,
    required this.payroll,
    required this.onUpdated,
    required this.ratesFor,
  });

  final dynamic l10n;
  final bool canConfigure;
  final bool canManageExpenses;
  final PayrollStoreData payroll;
  final Future<void> Function(PayrollStoreData) onUpdated;
  final StaffPayrollConfig Function(StaffMember) ratesFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProvider);
    final today = PayrollStore.todayDateStr();
    return staffAsync.when(
      loading: () => const ShimmerList(),
      error: (e, _) => ErrorState(message: e.toString(), title: l10n.somethingWentWrong, retryLabel: l10n.retry),
      data: (staff) {
        if (!canConfigure) {
          return Column(
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(l10n.noPermissionAllowances)),
              Expanded(child: _allowanceList(staff, today, ref, context)),
            ],
          );
        }
        return _allowanceList(staff, today, ref, context);
      },
    );
  }

  Widget _allowanceList(List<StaffMember> staff, String today, WidgetRef ref, BuildContext context) {
    if (staff.isEmpty) return EmptyState(icon: Icons.people_outline, title: l10n.noData);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staff.length,
      itemBuilder: (_, i) {
        final s = staff[i];
        final rates = ratesFor(s);
        final total = (rates.dailyFoodAllowance ?? 5000) + (rates.dailyTransportAllowance ?? 3000);
        final claimed = payroll.dailyAllowances.any((a) => a.staffId == s.id && a.date == today && a.status == 'claimed');
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${s.role} • ${AppFormatters.tsh(total)}/day', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 8),
            Row(children: [
              Chip(label: Text(claimed ? '✓ ${l10n.todayLabel}' : '⏳', style: const TextStyle(fontSize: 10))),
              const Spacer(),
              if (canConfigure && !claimed)
                TextButton(onPressed: () => _claim(context, ref, s, rates, total, today), child: Text(l10n.confirmAllowance)),
              if (canConfigure)
                TextButton(onPressed: () => _editRates(context, s, rates), child: Text(l10n.editRates)),
            ]),
          ]),
        );
      },
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref, StaffMember s, StaffPayrollConfig rates, double total, String today) async {
    final record = DailyAllowanceRecord(
      id: 'allow-${s.id}-$today',
      date: today,
      staffId: s.id,
      staffName: s.name,
      foodAmount: rates.dailyFoodAllowance ?? 5000,
      transportAmount: rates.dailyTransportAllowance ?? 3000,
      totalAmount: total,
    );
    final next = payroll.copyWith(
      dailyAllowances: [record, ...payroll.dailyAllowances.where((a) => !(a.staffId == s.id && a.date == today))],
    );
    await onUpdated(next);
    if (canManageExpenses) {
      try {
        await ref.read(apiClientProvider).createExpense({
          'title': 'Posho ya leo — ${s.name}',
          'category': 'daily_stipends_food_transport',
          'amount': total,
          'payment_method': 'cash_drawer',
          'recipient': s.name,
        });
        ref.read(expensesRefreshProvider.notifier).state++;
      } catch (_) {}
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentRecorded)));
    }
  }

  Future<void> _editRates(BuildContext context, StaffMember s, StaffPayrollConfig rates) async {
    final foodCtrl = TextEditingController(text: (rates.dailyFoodAllowance ?? 5000).toStringAsFixed(0));
    final transportCtrl = TextEditingController(text: (rates.dailyTransportAllowance ?? 3000).toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.editRates),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: foodCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.foodAllowance)),
          TextField(controller: transportCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.transportAllowance)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.saveChanges)),
        ],
      ),
    );
    if (ok != true) return;
    final cfg = StaffPayrollConfig(
      baseSalary: rates.baseSalary,
      dailyFoodAllowance: double.tryParse(foodCtrl.text) ?? 5000,
      dailyTransportAllowance: double.tryParse(transportCtrl.text) ?? 3000,
    );
    final map = Map<String, StaffPayrollConfig>.from(payroll.staffConfig);
    map[s.id] = cfg;
    await onUpdated(payroll.copyWith(staffConfig: map));
  }
}

class _PayrollTab extends ConsumerWidget {
  const _PayrollTab({
    required this.l10n,
    required this.canPayroll,
    required this.canManageExpenses,
    required this.payroll,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onUpdated,
    required this.ratesFor,
  });

  final dynamic l10n;
  final bool canPayroll;
  final bool canManageExpenses;
  final PayrollStoreData payroll;
  final String selectedMonth;
  final ValueChanged<String> onMonthChanged;
  final Future<void> Function(PayrollStoreData) onUpdated;
  final StaffPayrollConfig Function(StaffMember) ratesFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProvider);
    return staffAsync.when(
      loading: () => const ShimmerList(),
      error: (e, _) => ErrorState(message: e.toString(), title: l10n.somethingWentWrong, retryLabel: l10n.retry),
      data: (staff) {
        if (staff.isEmpty) return EmptyState(icon: Icons.people_outline, title: l10n.noData);
        return Column(children: [
          if (!canPayroll)
            Padding(padding: const EdgeInsets.all(16), child: Text(l10n.noPermissionPayroll, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: staff.length,
              itemBuilder: (_, i) {
                final s = staff[i];
                final rates = ratesFor(s);
                final base = rates.baseSalary ?? 450000;
                final stipends = PayrollStore.monthAllowancesTotal(s.id, selectedMonth, payroll.dailyAllowances);
                final nssf = (base * 0.1).roundToDouble();
                final net = base - nssf;
                final paid = payroll.payrollRecords.any((p) => p.staffId == s.id && p.monthYear == selectedMonth);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${l10n.baseSalary}: ${AppFormatters.tsh(base)} • Posho: ${AppFormatters.tsh(stipends)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(AppFormatters.tsh(net), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                      paid
                          ? Chip(label: Text(l10n.paidStatus, style: const TextStyle(fontSize: 10)))
                          : canPayroll
                              ? TextButton(onPressed: () => _pay(context, ref, s, net), child: Text(l10n.payNow))
                              : Text(l10n.awaitingPayment, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ]),
                  ]),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  Future<void> _pay(BuildContext context, WidgetRef ref, StaffMember s, double net) async {
    final record = PayrollRecord(
      id: 'pay-${s.id}-$selectedMonth',
      monthYear: selectedMonth,
      staffId: s.id,
      staffName: s.name,
      netPayable: net,
    );
    await onUpdated(payroll.copyWith(
      payrollRecords: [record, ...payroll.payrollRecords.where((p) => !(p.staffId == s.id && p.monthYear == selectedMonth))],
    ));
    if (canManageExpenses) {
      try {
        await ref.read(apiClientProvider).createExpense({
          'title': 'Mshahara $selectedMonth — ${s.name}',
          'category': 'staff_salaries',
          'amount': net,
          'payment_method': 'bank_transfer',
          'recipient': s.name,
        });
        ref.read(expensesRefreshProvider.notifier).state++;
      } catch (_) {}
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.payrollProcessed)));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.count, required this.l10n});
  final double total;
  final int count;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: AppColors.dangerGradient,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.totalExpenses, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        Text(AppFormatters.tsh(total), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        Text(l10n.recordsCount(count), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ]),
      const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
    ]),
  );
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseItem expense;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ExpenseTile({required this.expense, this.canManage = false, this.onEdit, this.onDelete});

  static const _categoryIcons = {
    'rent': Icons.home_outlined,
    'utilities_luku': Icons.bolt_outlined,
    'staff_salaries': Icons.people_outline_rounded,
    'daily_stipends_food_transport': Icons.lunch_dining_outlined,
    'other': Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[expense.category] ?? Icons.receipt_outlined;
    final label = ExpenseItem.categoryLabels[expense.category] ?? expense.category;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.danger),
        title: Text(expense.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text('${AppFormatters.date(expense.date)} • $label', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(AppFormatters.tsh(expense.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
          if (canManage)
            Row(mainAxisSize: MainAxisSize.min, children: [
              InkWell(onTap: onEdit, child: const Icon(Icons.edit_outlined, size: 16)),
              InkWell(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger)),
            ]),
        ]),
      ),
    );
  }
}

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet({this.existing});
  final ExpenseItem? existing;
  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _recipCtrl = TextEditingController();
  String _category = 'other';
  String _payMethod = 'cash_drawer';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amtCtrl.text = e.amount.toStringAsFixed(0);
      _recipCtrl.text = e.recipient;
      _category = e.category;
      _payMethod = e.paymentMethod;
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _amtCtrl, _recipCtrl]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = ref.read(appLocalizationsProvider);
    try {
      final api = ref.read(apiClientProvider);
      final payload = {
        'title': _titleCtrl.text.trim(),
        'category': _category,
        'amount': double.tryParse(_amtCtrl.text) ?? 0,
        'payment_method': _payMethod,
        'recipient': _recipCtrl.text.trim(),
      };
      if (widget.existing != null) {
        await api.updateExpense(widget.existing!.id, payload);
      } else {
        await api.createExpense(payload);
      }
      ref.read(expensesRefreshProvider.notifier).state++;
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.existing != null ? l10n.saveChanges : l10n.expenseRecorded)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorMessage(e.toString())), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(controller: ctrl, children: [
            Text(widget.existing != null ? l10n.editExpense : l10n.recordExpense, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(controller: _titleCtrl, decoration: InputDecoration(labelText: l10n.titleRequired), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
            TextFormField(controller: _amtCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.amountRequired, prefixText: 'TSh ')),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(labelText: l10n.category),
              items: ExpenseItem.categoryLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            TextFormField(controller: _recipCtrl, decoration: InputDecoration(labelText: l10n.recipientVendor)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(double.infinity, 52)),
              child: Text(widget.existing != null ? l10n.saveChanges : l10n.recordExpense),
            ),
          ]),
        ),
      ),
    );
  }
}
