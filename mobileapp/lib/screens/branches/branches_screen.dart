import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/branch_model.dart';
import '../../providers/branches_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';

class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final branchesAsync = ref.watch(branchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.branchManagement,
        subtitle: l10n.multiLocationOverview,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.addBranchesWeb),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: branchesAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          title: l10n.somethingWentWrong,
          retryLabel: l10n.retry,
        ),
        data: (branches) {
          if (branches.isEmpty) return EmptyState(
            icon: Icons.store_outlined,
            title: l10n.noBranchesYet,
            subtitle: l10n.addFirstBranch,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BranchSummaryCard(branches: branches),
              const SizedBox(height: 16),
              ...branches.map((b) => _BranchCard(branch: b)),
            ],
          );
        },
      ),
    );
  }
}

class _BranchSummaryCard extends ConsumerWidget {
  final List<StoreBranch> branches;
  const _BranchSummaryCard({required this.branches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final totalGmv   = branches.fold(0.0, (s, b) => s + b.monthlyGmvTzs);
    final totalStock = branches.fold(0.0, (s, b) => s + b.stockValuationTzs);
    final active     = branches.where((b) => b.status == BranchStatus.active).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.gradientForBusiness('retail'),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(l10n.totalBranches, '${branches.length}', Colors.white),
              _SummaryItem(l10n.active, '$active', Colors.white),
              _SummaryItem(l10n.staff, '${branches.fold(0, (s, b) => s + b.staffCount)}', Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.monthlyRevenue, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                  Text(AppFormatters.compact(totalGmv),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.stockValue, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                  Text(AppFormatters.compact(totalStock),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10)),
    ],
  );
}

class _BranchCard extends ConsumerWidget {
  final StoreBranch branch;
  const _BranchCard({required this.branch});

  Color get _statusColor {
    switch (branch.status) {
      case BranchStatus.active:     return AppColors.success;
      case BranchStatus.inactive:   return AppColors.textHint;
      case BranchStatus.renovation: return AppColors.warning;
      case BranchStatus.closed:     return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.store_rounded, color: primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(branch.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('${branch.district}, ${branch.region}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(branch.status.name.toUpperCase(),
                  style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _BranchStat(l10n.dailyRevenue, AppFormatters.tsh(branch.dailyGmvTzs))),
              Expanded(child: _BranchStat(l10n.monthly, AppFormatters.compact(branch.monthlyGmvTzs))),
              Expanded(child: _BranchStat(l10n.staff, '${branch.staffCount}')),
              Expanded(child: _BranchStat(l10n.stockValue, AppFormatters.compact(branch.stockValuationTzs))),
            ],
          ),
          if (branch.managerName != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.manage_accounts_outlined, size: 16, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(l10n.managerLabel(branch.managerName!),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.stockTransfersWeb),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: Text(l10n.transferStock, style: const TextStyle(fontSize: 12)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => ref.read(activeBranchIdProvider.notifier).state = branch.id,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(l10n.manage, style: const TextStyle(fontSize: 12)),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchStat extends StatelessWidget {
  final String label;
  final String value;
  const _BranchStat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textHint), textAlign: TextAlign.center),
    ],
  );
}
