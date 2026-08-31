import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/drawer_menu_button.dart';
import '../../widgets/empty_state.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(currentUserProvider);
    final bizType = ref.watch(businessTypeProvider);
    final statsAsync = ref.watch(refreshedDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(dashboardRefreshProvider.notifier).state++,
        child: CustomScrollView(
          slivers: [
            // ── Gradient hero header ────────────────────────────
            SliverToBoxAdapter(child: _HeroHeader(user: user, bizType: bizType)),

            statsAsync.when(
              loading: () => const SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [
                  ShimmerStatCardRow(), SizedBox(height: 12), ShimmerStatCardRow(),
                ]),
              )),
              error: (e, _) {
                final l10n = ref.watch(appLocalizationsProvider);
                return SliverToBoxAdapter(child: ErrorState(
                  message: e.toString(),
                  title: l10n.somethingWentWrong,
                  retryLabel: l10n.retry,
                  onRetry: () => ref.read(dashboardRefreshProvider.notifier).state++,
                ));
              },
              data: (stats) => SliverToBoxAdapter(
                child: _DashboardBody(stats: stats, bizType: bizType),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends ConsumerWidget {
  final dynamic user;
  final String bizType;
  const _HeroHeader({required this.user, required this.bizType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final gradient = AppColors.gradientForBusiness(bizType);
    final bizInfo  = AppConstants.businessTypes.firstWhere(
      (t) => t['id'] == bizType, orElse: () => AppConstants.businessTypes[2]);
    final now = DateTime.now();

    String greeting = l10n.goodMorning;
    if (now.hour >= 12 && now.hour < 17) greeting = l10n.goodAfternoon;
    if (now.hour >= 17) greeting = l10n.goodEvening;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DrawerMenuButton(),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        Text(user?.name ?? l10n.owner,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(bizInfo['icon']!, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(user?.businessName ?? bizInfo['label_en']!,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification + Settings
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.noNewNotifications),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: () => GoRouter.of(context).go('/settings'),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Text(
                        (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(AppFormatters.date(DateTime.now()),
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final DashboardStats stats;
  final String bizType;
  const _DashboardBody({required this.stats, required this.bizType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final access = ref.watch(roleAccessProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top KPI cards ─────────────────────────────────────
          Row(children: [
            Expanded(child: StatCard(
              label: l10n.todaysSales,
              value: AppFormatters.tsh(stats.todayRevenue),
              subValue: l10n.transactionsCount(stats.todaySalesCount),
              icon: Icons.trending_up_rounded,
              gradient: AppColors.gradientForBusiness(bizType),
              onTap: access?.canSeeReports == true
                  ? () => GoRouter.of(context).go('/reports')
                  : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: StatCard(
              label: l10n.thisMonth,
              value: AppFormatters.compact(stats.monthRevenue),
              subValue: l10n.thisWeekAmount(AppFormatters.tsh(stats.weekRevenue)),
              icon: Icons.calendar_month_rounded,
              gradient: AppColors.purpleGradient,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            if (access?.canSeeInventory == true)
              Expanded(child: StatCard(
                label: l10n.stockValue,
                value: AppFormatters.compact(stats.stockValue),
                icon: Icons.inventory_2_rounded,
                gradient: AppColors.tealGradient,
                onTap: () => GoRouter.of(context).go('/inventory'),
              )),
            if (access?.canSeeInventory == true && access?.canSeeReceivables == true)
              const SizedBox(width: 12),
            if (access?.canSeeReceivables == true)
              Expanded(child: StatCard(
                label: l10n.receivables,
                value: AppFormatters.compact(stats.totalReceivables),
                icon: Icons.account_balance_wallet_rounded,
                gradient: AppColors.warningGradient,
                onTap: () => GoRouter.of(context).go('/credit'),
              )),
          ]),

          // ── Alert tiles ───────────────────────────────────────
          if (stats.lowStockCount > 0 || stats.expiringCount > 0) ...[
            if (access?.canSeeInventory == true) ...[
            const SizedBox(height: 16),
            Row(children: [
              if (stats.lowStockCount > 0)
                Expanded(child: _AlertTile(
                  label: l10n.lowStock,
                  count: stats.lowStockCount,
                  color: AppColors.warning,
                  icon: Icons.warning_amber_rounded,
                  onTap: () => GoRouter.of(context).go('/inventory'),
                  l10n: l10n,
                )),
              if (stats.lowStockCount > 0 && stats.expiringCount > 0)
                const SizedBox(width: 10),
              if (stats.expiringCount > 0)
                Expanded(child: _AlertTile(
                  label: l10n.expiringSoon,
                  count: stats.expiringCount,
                  color: AppColors.danger,
                  icon: Icons.timer_off_outlined,
                  onTap: () => GoRouter.of(context).go('/inventory'),
                  l10n: l10n,
                )),
            ]),
            ],
          ],

          // ── Revenue chart ─────────────────────────────────────
          if (access?.canSeeReports == true) ...[
          const SizedBox(height: 20),
          _SectionHeader(title: l10n.revenueTrend, action: l10n.viewReports,
            onAction: () => GoRouter.of(context).go('/reports')),
          const SizedBox(height: 12),
          _RevenueChart(points: stats.revenueTrend, bizType: bizType),
          ],

          // ── Payment breakdown ─────────────────────────────────
          if (stats.paymentBreakdown.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(title: l10n.paymentMethods),
            const SizedBox(height: 12),
            _PaymentBreakdown(data: stats.paymentBreakdown, l10n: l10n),
          ],

          // ── Top products ──────────────────────────────────────
          if (stats.topProducts.isNotEmpty && access?.canSeeInventory == true) ...[
            const SizedBox(height: 20),
            _SectionHeader(title: l10n.topProducts, action: l10n.seeAll,
              onAction: () => GoRouter.of(context).go('/inventory')),
            const SizedBox(height: 12),
            ...stats.topProducts.take(4).map((p) => _TopProductTile(product: p, l10n: l10n)),
          ],

          // ── Quick actions ─────────────────────────────────────
          const SizedBox(height: 20),
          _SectionHeader(title: l10n.quickActions),
          const SizedBox(height: 12),
          _QuickActions(),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final AppLocalizations l10n;

  const _AlertTile({required this.label, required this.count, required this.color, required this.icon, this.onTap, required this.l10n});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.itemsCount(count), style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Text(action!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
        ),
    ],
  );
}

class _RevenueChart extends StatelessWidget {
  final List<RevenuePoint> points;
  final String bizType;
  const _RevenueChart({required this.points, required this.bizType});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final primary = AppColors.forBusiness(bizType);
    final maxY = points.map((p) => p.revenue).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Text(points[i].label, style: const TextStyle(fontSize: 10, color: AppColors.textHint));
                },
                reservedSize: 20,
              ),
            ),
          ),
          minX: 0, maxX: (points.length - 1).toDouble(),
          minY: 0, maxY: maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue)).toList(),
              isCurved: true,
              color: primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [primary.withOpacity(0.3), primary.withOpacity(0.0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  final Map<String, double> data;
  final AppLocalizations l10n;
  const _PaymentBreakdown({required this.data, required this.l10n});

  static const _icons = {
    'cash': Icons.money_rounded,
    'mpesa': Icons.phone_android_rounded,
    'airtel': Icons.sim_card_rounded,
    'tigopesa': Icons.sim_card_rounded,
    'card': Icons.credit_card_rounded,
    'credit': Icons.account_balance_rounded,
  };

  static const _colors = {
    'cash':     AppColors.success,
    'mpesa':    AppColors.primaryLight,
    'airtel':   AppColors.accentRed,
    'tigopesa': AppColors.accentOrange,
    'card':     AppColors.accentPurple,
    'credit':   AppColors.accentTeal,
  };

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (s, v) => s + v);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: data.entries.map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          final color = _colors[e.key] ?? AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(_icons[e.key] ?? Icons.payment_rounded, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.paymentMethodLabel(e.key),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text(AppFormatters.tsh(e.value),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct, minHeight: 5,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final TopProduct product;
  final AppLocalizations l10n;
  const _TopProductTile({required this.product, required this.l10n});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name.isNotEmpty ? product.name : l10n.unknownProduct,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Text(l10n.unitsSold(product.quantity), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text(AppFormatters.tsh(product.revenue),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ],
    ),
  );
}

class _QuickActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final access = ref.watch(roleAccessProvider);
    final allActions = [
      if (access?.canSeePOS == true)
        {'icon': Icons.point_of_sale_rounded, 'label': l10n.newSale, 'path': '/pos', 'color': AppColors.success},
      if (access?.canSeeInventory == true)
        {'icon': Icons.add_box_outlined, 'label': l10n.addProduct, 'path': '/inventory', 'color': primary},
      if (access?.canSeeCustomers == true)
        {'icon': Icons.people_outline_rounded, 'label': l10n.customers, 'path': '/customers', 'color': AppColors.accentPurple},
      if (access?.canSeeSuppliers == true)
        {'icon': Icons.local_shipping_outlined, 'label': l10n.suppliers, 'path': '/suppliers', 'color': AppColors.accentOrange},
      if (access?.canSeePending == true)
        {'icon': Icons.pending_actions_outlined, 'label': l10n.pending, 'path': '/pending', 'color': AppColors.warning},
      if (access?.canSeeBI == true)
        {'icon': Icons.insights_outlined, 'label': l10n.profitBi, 'path': '/bi', 'color': AppColors.accentOrange},
    ];

    if (allActions.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: allActions.length.clamp(2, 4),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: allActions.length,
      itemBuilder: (_, i) {
        final a = allActions[i];
        final color = a['color'] as Color;
        return GestureDetector(
          onTap: () => GoRouter.of(context).go(a['path'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a['icon'] as IconData, color: color, size: 24),
                const SizedBox(height: 6),
                Text(a['label'] as String,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
