import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/bi/bi_compute.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bi_provider.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';

class BiAnalyticsScreen extends ConsumerWidget {
  const BiAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final bizType = ref.watch(businessTypeProvider);
    final biAsync = ref.watch(biSnapshotProvider);
    final range = ref.watch(biTimeRangeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.profitAnalysis,
        subtitle: l10n.biLiveSubtitle,
        actions: [
          PopupMenuButton<BiTimeRange>(
            icon: const Icon(Icons.date_range_rounded, color: Colors.white),
            onSelected: (r) => ref.read(biTimeRangeProvider.notifier).state = r,
            itemBuilder: (_) => [
              PopupMenuItem(value: BiTimeRange.month, child: Text(l10n.thisMonth)),
              PopupMenuItem(value: BiTimeRange.quarter, child: Text(l10n.thisQuarter)),
              PopupMenuItem(value: BiTimeRange.year, child: Text(l10n.thisYear)),
              PopupMenuItem(value: BiTimeRange.all, child: Text(l10n.allTime)),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(biRefreshProvider.notifier).state++;
          ref.read(salesRefreshProvider.notifier).state++;
        },
        child: biAsync.when(
          loading: () => const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              ShimmerStatCardRow(),
              SizedBox(height: 12),
              ShimmerStatCardRow(),
            ]),
          ),
          error: (e, _) => ListView(
            children: [
              ErrorState(
                message: l10n.errorLoadingBi(e.toString()),
                title: l10n.somethingWentWrong,
                retryLabel: l10n.retry,
                onRetry: () => ref.read(biRefreshProvider.notifier).state++,
              ),
            ],
          ),
          data: (bi) => _BiBody(bi: bi, bizType: bizType, range: range),
        ),
      ),
    );
  }
}

class _BiBody extends ConsumerWidget {
  final BiSnapshot bi;
  final String bizType;
  final BiTimeRange range;

  const _BiBody({required this.bi, required this.bizType, required this.range});

  String _rangeLabel(AppLocalizations l10n) {
    switch (range) {
      case BiTimeRange.quarter:
        return l10n.quarter;
      case BiTimeRange.year:
        return l10n.year;
      case BiTimeRange.all:
        return l10n.allTimeLower;
      default:
        return l10n.month;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final primary = AppColors.forBusiness(bizType);
    final marginPct =
        bi.grossSales > 0 ? (bi.grossMargin / bi.grossSales * 100) : 0.0;
    final netPct =
        bi.grossSales > 0 ? (bi.netProfit / bi.grossSales * 100) : 0.0;
    final rangeLabel = _rangeLabel(l10n);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.performanceLabel(rangeLabel),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: StatCard(
                label: l10n.grossSales,
                value: AppFormatters.compact(bi.grossSales),
                subValue: bi.momChange.hasData
                    ? l10n.momChange(
                        bi.momChange.direction == 'up' ? '↑' : bi.momChange.direction == 'down' ? '↓' : '→',
                        bi.momChange.percent.toString(),
                      )
                    : null,
                icon: Icons.trending_up_rounded,
                gradient: AppColors.gradientForBusiness(bizType),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: l10n.netProfit,
                value: AppFormatters.compact(bi.netProfit),
                subValue: l10n.marginPercent(netPct.toStringAsFixed(1)),
                icon: Icons.savings_outlined,
                gradient: AppColors.successGradient,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: StatCard(
                label: l10n.cogs,
                value: AppFormatters.compact(bi.cogs),
                icon: Icons.inventory_outlined,
                gradient: AppColors.warningGradient,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: l10n.opex,
                value: AppFormatters.compact(bi.totalOpex),
                icon: Icons.receipt_long_outlined,
                gradient: AppColors.dangerGradient,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          StatCard(
            label: l10n.grossMargin,
            value: AppFormatters.compact(bi.grossMargin),
            subValue: l10n.percentOfSales(marginPct.toStringAsFixed(1)),
            icon: Icons.pie_chart_outline_rounded,
            gradient: AppColors.purpleGradient,
          ),

          const SizedBox(height: 20),
          _SectionTitle(l10n.monthlyPlTrend),
          const SizedBox(height: 10),
          _PlChart(rows: bi.monthlyPl, color: primary, emptyMessage: l10n.noPlData),

          if (bi.categoryProfits.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(l10n.topCategoriesByProfit),
            const SizedBox(height: 10),
            ...bi.categoryProfits.take(4).map((c) => _CategoryTile(row: c)),
          ],

          if (bi.topProducts.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(l10n.productProfitLeaders),
            const SizedBox(height: 10),
            ...bi.topProducts.take(5).map((p) => _ProductInsightTile(p: p)),
          ],

          if (bi.costSavings.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(l10n.costSavingOpportunities),
            const SizedBox(height: 10),
            ...bi.costSavings.map((o) => _SavingCard(op: o)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
}

class _PlChart extends StatelessWidget {
  final List<MonthlyPlRow> rows;
  final Color color;
  final String emptyMessage;
  const _PlChart({required this.rows, required this.color, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (rows.every((r) => r.revenue == 0 && r.netProfit == 0)) {
      return _EmptyChart(message: emptyMessage);
    }
    final maxY = rows
        .map((r) => [r.revenue, r.netProfit.abs()].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                  return Text(rows[i].month,
                      style: const TextStyle(fontSize: 10, color: AppColors.textHint));
                },
              ),
            ),
          ),
          barGroups: rows.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.revenue,
                  color: color.withValues(alpha: 0.5),
                  width: 10,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: e.value.netProfit.clamp(0, double.infinity),
                  color: AppColors.success,
                  width: 10,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
}

class _CategoryTile extends ConsumerWidget {
  final CategoryProfitRow row;
  const _CategoryTile({required this.row});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.category,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(l10n.marginShare('${row.marginPercent}', '${row.profitSharePercent}'),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(AppFormatters.tsh(row.profit),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      );
  }
}

class _ProductInsightTile extends ConsumerWidget {
  final ProductBiInsight p;
  const _ProductInsightTile({required this.p});

  Color get _paretoColor {
    switch (p.paretoClass) {
      case 'A':
        return AppColors.success;
      case 'B':
        return AppColors.warning;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _paretoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(l10n.paretoClass(p.paretoClass),
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: _paretoColor)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(l10n.marginSold('${p.marginPercent}', p.monthlySalesVolume.toStringAsFixed(0)),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(AppFormatters.compact(p.monthlyGrossProfit),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      );
  }
}

class _SavingCard extends StatelessWidget {
  final CostSavingOpportunity op;
  const _SavingCard({required this.op});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(op.tag,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success)),
                ),
                const Spacer(),
                Text(op.savingsLabel,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 8),
            Text(op.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(op.description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
}
