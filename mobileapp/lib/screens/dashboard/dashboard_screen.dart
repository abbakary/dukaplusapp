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
import '../../providers/ai_provider.dart';
import '../../widgets/ai_assistant_fab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Screen
// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user       = ref.watch(currentUserProvider);
    final bizType    = ref.watch(businessTypeProvider);
    final statsAsync = ref.watch(refreshedDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.forBusiness(bizType),
        backgroundColor: Colors.white,
        displacement: 60,
        onRefresh: () async =>
            ref.read(dashboardRefreshProvider.notifier).state++,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // ── Sticky gradient header ──────────────────────────
            SliverToBoxAdapter(
              child: _HeroHeader(user: user, bizType: bizType),
            ),

            statsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _DashboardSkeleton(),
                ),
              ),
              error: (e, _) {
                final l10n = ref.watch(appLocalizationsProvider);
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorState(
                      message:    e.toString(),
                      title:      l10n.somethingWentWrong,
                      retryLabel: l10n.retry,
                      onRetry: () =>
                          ref.read(dashboardRefreshProvider.notifier).state++,
                    ),
                  ),
                );
              },
              data: (stats) => SliverToBoxAdapter(
                child: _DashboardBody(stats: stats, bizType: bizType),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────
class _HeroHeader extends ConsumerWidget {
  final dynamic user;
  final String bizType;
  const _HeroHeader({required this.user, required this.bizType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n     = ref.watch(appLocalizationsProvider);
    final gradient = AppColors.gradientForBusiness(bizType);
    final bizInfo  = AppConstants.businessTypes.firstWhere(
        (t) => t['id'] == bizType,
        orElse: () => AppConstants.businessTypes[2]);
    final now    = DateTime.now();
    final hourly = _greeting(now.hour, l10n);

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drawer button
              const DrawerMenuButton(),
              const SizedBox(width: 10),
              // Greeting block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hourly,
                      style: TextStyle(
                        color:    Colors.white.withValues(alpha: 0.80),
                        fontSize: 12,
                      )),
                    const SizedBox(height: 2),
                    Text(
                      user?.name ?? l10n.owner,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Business pill
                    Container(
                      constraints: const BoxConstraints(maxWidth: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(bizInfo['icon']!,
                            style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              user?.businessName ?? bizInfo['label_en']!,
                              style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Right actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Date
                  Text(AppFormatters.date(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 10,
                    )),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // AI assistant
                      _HeaderIconBtn(
                        icon: Icons.auto_awesome_rounded,
                        onTap: () => ref.read(aiChatProvider.notifier).open(),
                      ),
                      const SizedBox(width: 6),
                      // Notification
                      _HeaderIconBtn(
                        icon: Icons.notifications_outlined,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.noNewNotifications),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      // Avatar
                      GestureDetector(
                        onTap: () => GoRouter.of(context).go('/settings'),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize:   14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(int hour, AppLocalizations l10n) {
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Body
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardBody extends ConsumerWidget {
  final DashboardStats stats;
  final String bizType;
  const _DashboardBody({required this.stats, required this.bizType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n   = ref.watch(appLocalizationsProvider);
    final access = ref.watch(roleAccessProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── AI Brief (matches web dashboard) ─────────────────────
          if (access?.canSeeDashboard == true) ...[
            AiPromptChip(
              expanded: true,
              label: l10n.aiBrief,
              prompt: l10n.aiDashboardPrompt,
            ),
            const SizedBox(height: 14),
          ],

          // ── KPI row 1: Today + Month ────────────────────────────
          Row(children: [
            Expanded(child: StatCard(
              label:    l10n.todaysSales,
              value:    AppFormatters.tsh(stats.todayRevenue),
              subValue: l10n.transactionsCount(stats.todaySalesCount),
              icon:     Icons.trending_up_rounded,
              gradient: AppColors.gradientForBusiness(bizType),
              onTap:    access?.canSeeReports == true
                  ? () => GoRouter.of(context).go('/reports') : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: StatCard(
              label:    l10n.thisMonth,
              value:    AppFormatters.compact(stats.monthRevenue),
              subValue: l10n.thisWeekAmount(AppFormatters.tsh(stats.weekRevenue)),
              icon:     Icons.calendar_month_rounded,
              gradient: AppColors.purpleGradient,
            )),
          ]),
          const SizedBox(height: 12),

          // ── KPI row 2: Stock + Receivables ──────────────────────
          if (access?.canSeeInventory == true || access?.canSeeReceivables == true)
            Row(children: [
              if (access?.canSeeInventory == true)
                Expanded(child: StatCard(
                  label:    l10n.stockValue,
                  value:    AppFormatters.compact(stats.stockValue),
                  icon:     Icons.inventory_2_rounded,
                  gradient: AppColors.tealGradient,
                  onTap:    () => GoRouter.of(context).go('/inventory'),
                )),
              if (access?.canSeeInventory == true &&
                  access?.canSeeReceivables == true)
                const SizedBox(width: 12),
              if (access?.canSeeReceivables == true)
                Expanded(child: StatCard(
                  label:    l10n.receivables,
                  value:    AppFormatters.compact(stats.totalReceivables),
                  icon:     Icons.account_balance_wallet_rounded,
                  gradient: AppColors.warningGradient,
                  onTap:    () => GoRouter.of(context).go('/credit'),
                )),
            ]),

          // ── Alert tiles ─────────────────────────────────────────
          if (access?.canSeeInventory == true &&
              (stats.lowStockCount > 0 || stats.expiringCount > 0)) ...[
            const SizedBox(height: 16),
            Row(children: [
              if (stats.lowStockCount > 0)
                Expanded(child: _AlertTile(
                  label: l10n.lowStock,
                  count: stats.lowStockCount,
                  color: AppColors.warning,
                  icon:  Icons.warning_amber_rounded,
                  l10n:  l10n,
                  onTap: () => GoRouter.of(context).go('/inventory'),
                )),
              if (stats.lowStockCount > 0 && stats.expiringCount > 0)
                const SizedBox(width: 10),
              if (stats.expiringCount > 0)
                Expanded(child: _AlertTile(
                  label: l10n.expiringSoon,
                  count: stats.expiringCount,
                  color: AppColors.danger,
                  icon:  Icons.timer_off_outlined,
                  l10n:  l10n,
                  onTap: () => GoRouter.of(context).go('/inventory'),
                )),
            ]),
          ],

          // ── Revenue trend chart ─────────────────────────────────
          if (access?.canSeeReports == true && stats.revenueTrend.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              title: l10n.revenueTrend,
              action: l10n.viewReports,
              onAction: () => GoRouter.of(context).go('/reports'),
            ),
            const SizedBox(height: 10),
            _RevenueChart(points: stats.revenueTrend, bizType: bizType),
          ],

          // ── Quick actions ───────────────────────────────────────
          const SizedBox(height: 20),
          _SectionHeader(title: l10n.quickActions),
          const SizedBox(height: 10),
          _QuickActions(),

          // ── Payment breakdown ───────────────────────────────────
          if (stats.paymentBreakdown.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(title: l10n.paymentMethods),
            const SizedBox(height: 10),
            _PaymentBreakdown(data: stats.paymentBreakdown, l10n: l10n),
          ],

          // ── Top products ────────────────────────────────────────
          if (stats.topProducts.isNotEmpty && access?.canSeeInventory == true) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              title: l10n.topProducts,
              action: l10n.seeAll,
              onAction: () => GoRouter.of(context).go('/inventory'),
            ),
            const SizedBox(height: 10),
            ...stats.topProducts
                .take(4)
                .map((p) => _TopProductTile(product: p, l10n: l10n)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert Tile
// ─────────────────────────────────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final AppLocalizations l10n;

  const _AlertTile({
    required this.label, required this.count, required this.color,
    required this.icon, required this.l10n, this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.itemsCount(count),
                  style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w800)),
                Text(label,
                  style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 18),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title,
        style: const TextStyle(
          fontSize:   15,
          fontWeight: FontWeight.w700,
          color:      AppColors.textPrimary,
          letterSpacing: -0.2,
        )),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(action!,
              style: TextStyle(
                fontSize:   11,
                color:      Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              )),
          ),
        ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Revenue Chart
// ─────────────────────────────────────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final List<RevenuePoint> points;
  final String bizType;
  const _RevenueChart({required this.points, required this.bizType});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final primary = AppColors.forBusiness(bizType);
    final maxY    = points.map((p) => p.revenue).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 175,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(points[i].label,
                      style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint)),
                  );
                },
                reservedSize: 22,
              ),
            ),
          ),
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary,
              tooltipRoundedRadius: 8,
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  AppFormatters.compact(s.y),
                  const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                  .toList(),
              isCurved:      true,
              curveSmoothness: 0.35,
              color:         primary,
              barWidth:      2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.22),
                    primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeOutCubic,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Breakdown
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentBreakdown extends StatelessWidget {
  final Map<String, double> data;
  final AppLocalizations l10n;
  const _PaymentBreakdown({required this.data, required this.l10n});

  static const _icons = {
    'cash':     Icons.money_rounded,
    'mpesa':    Icons.phone_android_rounded,
    'airtel':   Icons.sim_card_rounded,
    'tigopesa': Icons.sim_card_rounded,
    'card':     Icons.credit_card_rounded,
    'credit':   Icons.account_balance_rounded,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: data.entries.map((e) {
          final pct   = total > 0 ? e.value / total : 0.0;
          final color = _colors[e.key] ?? AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_icons[e.key] ?? Icons.payment_rounded,
                    color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.paymentMethodLabel(e.key),
                            style: const TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              color:      AppColors.textPrimary)),
                          Text(AppFormatters.tsh(e.value),
                            style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:           pct,
                          minHeight:       5,
                          backgroundColor: AppColors.divider,
                          valueColor:      AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(pct * 100).round()}%',
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                    color:      color,
                  )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Product Tile
// ─────────────────────────────────────────────────────────────────────────────
class _TopProductTile extends StatelessWidget {
  final TopProduct product;
  final AppLocalizations l10n;
  const _TopProductTile({required this.product, required this.l10n});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name.isNotEmpty ? product.name : l10n.unknownProduct,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              ),
              Text(l10n.unitsSold(product.quantity),
                style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text(AppFormatters.tsh(product.revenue),
          style: const TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w700,
            color:      AppColors.primary)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Grid
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n   = ref.watch(appLocalizationsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final access = ref.watch(roleAccessProvider);

    final allActions = [
      if (access?.canSeePOS == true)
        _Action(Icons.point_of_sale_rounded, l10n.newSale, '/pos', AppColors.success),
      if (access?.canSeeInventory == true)
        _Action(Icons.add_box_outlined, l10n.addProduct, '/inventory', primary),
      if (access?.canSeeCustomers == true)
        _Action(Icons.people_outline_rounded, l10n.customers, '/customers', AppColors.accentPurple),
      if (access?.canSeeSuppliers == true)
        _Action(Icons.local_shipping_outlined, l10n.suppliers, '/suppliers', AppColors.accentOrange),
      if (access?.canSeePending == true)
        _Action(Icons.pending_actions_outlined, l10n.pending, '/pending', AppColors.warning),
      if (access?.canSeeBI == true)
        _Action(Icons.insights_outlined, l10n.profitBi, '/bi', AppColors.accentOrange),
    ];

    if (allActions.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics:    const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:  allActions.length.clamp(2, 4),
        mainAxisSpacing:  10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: allActions.length,
      itemBuilder: (_, i) {
        final a = allActions[i];
        return _QuickActionTile(action: a);
      },
    );
  }
}

class _Action {
  final IconData icon;
  final String   label;
  final String   path;
  final Color    color;
  const _Action(this.icon, this.label, this.path, this.color);
}

class _QuickActionTile extends StatefulWidget {
  final _Action action;
  const _QuickActionTile({super.key, required this.action});

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) {
        _ctrl.reverse();
        GoRouter.of(context).go(a.path);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color:        a.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: a.color.withValues(alpha: 0.20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color:        a.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a.icon, color: a.color, size: 22),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(a.label,
                  style: TextStyle(
                    fontSize:   10.5,
                    fontWeight: FontWeight.w600,
                    color:      a.color,
                    height:     1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton loader
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerStatCardRow(),
        SizedBox(height: 12),
        ShimmerStatCardRow(),
        SizedBox(height: 16),
        ShimmerBox(width: double.infinity, height: 175, radius: 16),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 52, radius: 12),
      ],
    );
  }
}
