import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_pdf_builder.dart';
import 'package:go_router/go_router.dart';
import '../../core/rbac/role_access.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../data/models/dashboard_model.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/stat_card.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/ai_assistant_fab.dart';
import '../../widgets/shell_insets.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final bizType    = ref.watch(businessTypeProvider);
    final statsAsync = ref.watch(refreshedDashboardProvider);
    final access     = ref.watch(roleAccessProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.reports,
        subtitle: l10n.reportsSubtitle,
        actions: [
          AiAppBarButton(prompt: l10n.aiReportsPrompt),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            tooltip: 'Export PDF',
            onPressed: () async {
              final stats = ref.read(refreshedDashboardProvider).valueOrNull;
              if (stats == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.loading),
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              try {
                await exportSalesReportPdf(
                  user:  ref.read(currentUserProvider),
                  stats: stats,
                  isSw:  ref.read(localeProvider) == AppLanguage.sw,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.errorMessage(e.toString())),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(dashboardRefreshProvider.notifier).state++,
        child: statsAsync.when(
          loading: () => const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(children: [ShimmerStatCardRow(), SizedBox(height: 12), ShimmerStatCardRow()]),
          ),
          error: (e, _) => Center(child: Text('${l10n.error}: $e')),
          data: (stats) => _ReportsBody(stats: stats, bizType: bizType, showBiLink: access?.canSeeBI == true, l10n: l10n),
        ),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final DashboardStats stats;
  final String bizType;
  final bool showBiLink;
  final AppLocalizations l10n;
  const _ReportsBody({required this.stats, required this.bizType, this.showBiLink = false, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.forBusiness(bizType);
    return SingleChildScrollView(
      padding: ShellInsets.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBiLink) ...[
            Material(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => GoRouter.of(context).go('/bi'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.insights_rounded, color: AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.profitBi,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(l10n.profitBiSubtitle,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Period selector
          _PeriodSelector(l10n: l10n),
          const SizedBox(height: 16),
          // KPI row
          Row(children: [
            Expanded(child: StatCard(
              label: l10n.today,
              value: AppFormatters.tsh(stats.todayRevenue),
              subValue: l10n.salesCount(stats.todaySalesCount),
              icon: Icons.today_rounded,
              gradient: AppColors.gradientForBusiness(bizType),
            )),
            const SizedBox(width: 12),
            Expanded(child: StatCard(
              label: l10n.thisMonth,
              value: AppFormatters.compact(stats.monthRevenue),
              icon: Icons.calendar_month_rounded,
              gradient: AppColors.purpleGradient,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: StatCard(
              label: l10n.receivables,
              value: AppFormatters.compact(stats.totalReceivables),
              icon: Icons.account_balance_wallet_rounded,
              gradient: AppColors.warningGradient,
            )),
            const SizedBox(width: 12),
            Expanded(child: StatCard(
              label: l10n.payables,
              value: AppFormatters.compact(stats.totalPayables),
              icon: Icons.payments_outlined,
              gradient: AppColors.dangerGradient,
            )),
          ]),

          // Revenue chart
          const SizedBox(height: 20),
          _SectionLabel(l10n.revenueTrend7Days),
          const SizedBox(height: 12),
          if (stats.revenueTrend.isNotEmpty)
            _BarChartWidget(points: stats.revenueTrend, color: primary),

          // Payment breakdown pie
          if (stats.paymentBreakdown.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionLabel(l10n.paymentMethodsBreakdown),
            const SizedBox(height: 12),
            _PaymentPieChart(data: stats.paymentBreakdown),
          ],

          // Top products
          if (stats.topProducts.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionLabel(l10n.topProducts),
            const SizedBox(height: 12),
            _TopProductsChart(products: stats.topProducts, color: primary),
          ],
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final AppLocalizations l10n;
  const _PeriodSelector({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _PeriodSelectorBody(l10n: l10n);
  }
}

class _PeriodSelectorBody extends StatefulWidget {
  final AppLocalizations l10n;
  const _PeriodSelectorBody({required this.l10n});

  @override
  State<_PeriodSelectorBody> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelectorBody> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final labels = [l10n.today, l10n.week, l10n.month, l10n.year];
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == _selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppColors.textSecondary,
                  )),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(label,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
}

class _BarChartWidget extends StatelessWidget {
  final List<RevenuePoint> points;
  final Color color;
  const _BarChartWidget({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((p) => p.revenue).reduce((a, b) => a > b ? a : b);
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.3,
          barTouchData: BarTouchData(enabled: true),
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
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          barGroups: points.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [BarChartRodData(
              toY: e.value.revenue,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.6), color],
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
              ),
              width: 20, borderRadius: BorderRadius.circular(4),
            )],
          )).toList(),
        ),
      ),
    );
  }
}

class _PaymentPieChart extends StatefulWidget {
  final Map<String, double> data;
  const _PaymentPieChart({required this.data});

  @override
  State<_PaymentPieChart> createState() => _PaymentPieChartState();
}

class _PaymentPieChartState extends State<_PaymentPieChart> {
  int _touched = -1;

  static const _colors = [
    AppColors.success, AppColors.primaryLight, AppColors.accentOrange,
    AppColors.accentRed, AppColors.accentPurple, AppColors.accentTeal,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    final total   = widget.data.values.fold(0.0, (s, v) => s + v);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 140, width: 140,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (ev, res) => setState(() =>
                    _touched = res?.touchedSection?.touchedSectionIndex ?? -1),
                ),
                sections: entries.asMap().entries.map((e) {
                  final isTouched = e.key == _touched;
                  final pct = total > 0 ? e.value.value / total * 100 : 0;
                  return PieChartSectionData(
                    color: _colors[e.key % _colors.length],
                    value: e.value.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: isTouched ? 55 : 45,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  );
                }).toList(),
                centerSpaceRadius: 20,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: entries.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: _colors[e.key % _colors.length],
                        shape: BoxShape.circle,
                      )),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.value.key.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                    Text(AppFormatters.compact(e.value.value),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsChart extends StatelessWidget {
  final List<TopProduct> products;
  final Color color;
  const _TopProductsChart({required this.products, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxRev = products.map((p) => p.revenue).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: products.take(5).toList().asMap().entries.map((e) {
          final pct = maxRev > 0 ? e.value.revenue / maxRev : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(e.value.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(AppFormatters.tsh(e.value.revenue),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct, minHeight: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      color.withOpacity(0.6 + 0.4 * (1 - e.key / products.length)),
                    ),
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
