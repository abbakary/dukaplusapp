import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/payroll_store.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../widgets/gradient_app_bar.dart';

/// Compact banner for POS / home — cashier claims own daily posho without expenses hub.
class StipendClaimBanner extends ConsumerStatefulWidget {
  const StipendClaimBanner({super.key});

  @override
  ConsumerState<StipendClaimBanner> createState() => _StipendClaimBannerState();
}

class _StipendClaimBannerState extends ConsumerState<StipendClaimBanner> {
  bool _claimed = false;
  bool _loading = true;
  bool _claiming = false;
  double _total = 8000;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final tenantId = user.businessId ?? user.id;
    final staffId = user.staffId ?? user.id;
    final data = await PayrollStore.load(tenantId);
    final cfg = data.staffConfig[staffId];
    final food = cfg?.dailyFoodAllowance ?? 5000;
    final transport = cfg?.dailyTransportAllowance ?? 3000;
    final today = PayrollStore.todayDateStr();
    final claim = PayrollStore.findTodayClaim(staffId, today, data.dailyAllowances);
    if (mounted) {
      setState(() {
        _total = food + transport;
        _claimed = claim != null;
        _loading = false;
      });
    }
  }

  Future<void> _claim() async {
    if (_claimed || _claiming) return;
    setState(() => _claiming = true);
    final l10n = ref.read(appLocalizationsProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final tenantId = user.businessId ?? user.id;
    final staffId = user.staffId ?? user.id;
    final data = await PayrollStore.load(tenantId);
    final cfg = data.staffConfig[staffId];
    final food = cfg?.dailyFoodAllowance ?? 5000;
    final transport = cfg?.dailyTransportAllowance ?? 3000;

    try {
      await ref.read(apiClientProvider).claimDailyStipend(
        foodAmount: food,
        transportAmount: transport,
      );
      final record = DailyAllowanceRecord(
        id: 'allow-$staffId-${PayrollStore.todayDateStr()}',
        date: PayrollStore.todayDateStr(),
        staffId: staffId,
        staffName: user.name,
        foodAmount: food,
        transportAmount: transport,
        totalAmount: food + transport,
      );
      await PayrollStore.save(tenantId, data.copyWith(
        dailyAllowances: [record, ...data.dailyAllowances.where((a) => !(a.staffId == staffId && a.date == PayrollStore.todayDateStr()))],
      ));
      if (mounted) {
        setState(() => _claimed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentRecorded), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(roleAccessProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    if (access == null || !access.canClaimOwnStipend || _loading || _claimed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.warning.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0.12)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lunch_dining_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dailyStipends, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${AppFormatters.tsh(_total)} • ${l10n.todayLabel}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          FilledButton(
            onPressed: _claiming ? null : _claim,
            style: FilledButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: _claiming
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.confirmAllowance, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class MyStipendScreen extends ConsumerStatefulWidget {
  const MyStipendScreen({super.key});

  @override
  ConsumerState<MyStipendScreen> createState() => _MyStipendScreenState();
}

class _MyStipendScreenState extends ConsumerState<MyStipendScreen> {
  PayrollStoreData _store = const PayrollStoreData();
  bool _loaded = false;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final data = await PayrollStore.load(user.businessId ?? user.id);
    if (mounted) setState(() { _store = data; _loaded = true; });
  }

  Future<void> _claim() async {
    final user = ref.read(currentUserProvider);
    final access = ref.read(roleAccessProvider);
    if (user == null || access == null || !access.canClaimOwnStipend) return;

    setState(() => _claiming = true);
    final l10n = ref.read(appLocalizationsProvider);
    final tenantId = user.businessId ?? user.id;
    final staffId = user.staffId ?? user.id;
    final cfg = _store.staffConfig[staffId];
    final food = cfg?.dailyFoodAllowance ?? 5000;
    final transport = cfg?.dailyTransportAllowance ?? 3000;
    final today = PayrollStore.todayDateStr();

    try {
      await ref.read(apiClientProvider).claimDailyStipend(foodAmount: food, transportAmount: transport);
      final record = DailyAllowanceRecord(
        id: 'allow-$staffId-$today',
        date: today,
        staffId: staffId,
        staffName: user.name,
        foodAmount: food,
        transportAmount: transport,
        totalAmount: food + transport,
      );
      final next = _store.copyWith(
        dailyAllowances: [record, ..._store.dailyAllowances.where((a) => !(a.staffId == staffId && a.date == today))],
      );
      await PayrollStore.save(tenantId, next);
      if (mounted) {
        setState(() => _store = next);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentRecorded), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final user = ref.watch(currentUserProvider);
    final access = ref.watch(roleAccessProvider);

    if (access != null && !access.canClaimOwnStipend) {
      return Scaffold(
        appBar: GradientAppBar(title: l10n.dailyStipends),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.noPermissionAllowances, textAlign: TextAlign.center),
        )),
      );
    }

    final staffId = user?.staffId ?? user?.id ?? '';
    final today = PayrollStore.todayDateStr();
    final cfg = _store.staffConfig[staffId];
    final food = cfg?.dailyFoodAllowance ?? 5000;
    final transport = cfg?.dailyTransportAllowance ?? 3000;
    final total = food + transport;
    final claim = PayrollStore.findTodayClaim(staffId, today, _store.dailyAllowances);
    final monthTotal = PayrollStore.monthAllowancesTotal(staffId, PayrollStore.currentMonthStr(), _store.dailyAllowances);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.dailyStipends, subtitle: l10n.creditManagementSubtitle),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: claim != null ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: claim != null ? AppColors.success : AppColors.warning),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.todayLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('${l10n.foodAllowance}: ${AppFormatters.tsh(food)}'),
                    Text('${l10n.transportAllowance}: ${AppFormatters.tsh(transport)}'),
                    Text('${l10n.amountToPay}: ${AppFormatters.tsh(total)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.success)),
                    const SizedBox(height: 12),
                    if (claim != null)
                      Text('✓ ${l10n.paymentRecorded}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600))
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _claiming ? null : _claim,
                          style: FilledButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size.fromHeight(48)),
                          child: Text(_claiming ? l10n.loading : l10n.confirmAllowance),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
                Text(l10n.thisMonth, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${l10n.dailyStipends}: ${AppFormatters.tsh(monthTotal)}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
    );
  }
}
