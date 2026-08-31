import '../../data/models/customer_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/supplier_model.dart';

enum BiTimeRange { month, quarter, year, all }

class ProductBiInsight {
  final String productId;
  final String productName;
  final String category;
  final double unitPrice;
  final double costPrice;
  final double marginPercent;
  final double monthlySalesVolume;
  final double monthlyRevenue;
  final double monthlyGrossProfit;
  final double profitContributionPercent;
  final String paretoClass;
  final String stockHealthStatus;

  const ProductBiInsight({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unitPrice,
    required this.costPrice,
    required this.marginPercent,
    required this.monthlySalesVolume,
    required this.monthlyRevenue,
    required this.monthlyGrossProfit,
    required this.profitContributionPercent,
    required this.paretoClass,
    required this.stockHealthStatus,
  });
}

class CategoryProfitRow {
  final String category;
  final double profit;
  final double marginPercent;
  final double profitSharePercent;

  const CategoryProfitRow({
    required this.category,
    required this.profit,
    required this.marginPercent,
    required this.profitSharePercent,
  });
}

class MonthlyPlRow {
  final String month;
  final double revenue;
  final double cogs;
  final double opex;
  final double netProfit;

  const MonthlyPlRow({
    required this.month,
    required this.revenue,
    required this.cogs,
    required this.opex,
    required this.netProfit,
  });
}

class MomRevenueChange {
  final double percent;
  final bool hasData;
  final String direction;

  const MomRevenueChange({
    required this.percent,
    required this.hasData,
    required this.direction,
  });
}

class CostSavingOpportunity {
  final String id;
  final String savingsLabel;
  final String tag;
  final String title;
  final String description;

  const CostSavingOpportunity({
    required this.id,
    required this.savingsLabel,
    required this.tag,
    required this.title,
    required this.description,
  });
}

class BiSnapshot {
  final double grossSales;
  final double cogs;
  final double grossMargin;
  final double totalOpex;
  final double netProfit;
  final MomRevenueChange momChange;
  final List<CategoryProfitRow> categoryProfits;
  final List<MonthlyPlRow> monthlyPl;
  final List<ProductBiInsight> topProducts;
  final List<CostSavingOpportunity> costSavings;

  const BiSnapshot({
    required this.grossSales,
    required this.cogs,
    required this.grossMargin,
    required this.totalOpex,
    required this.netProfit,
    required this.momChange,
    required this.categoryProfits,
    required this.monthlyPl,
    required this.topProducts,
    required this.costSavings,
  });
}

List<SaleTransaction> filterSalesByTimeRange(
  List<SaleTransaction> sales,
  BiTimeRange range,
) {
  if (range == BiTimeRange.all) return sales;
  final now = DateTime.now();
  final cutoff = DateTime(now.year, now.month, now.day);
  if (range == BiTimeRange.month) {
    // cutoff is first of month
  } else if (range == BiTimeRange.quarter) {
    final qMonth = (now.month - 1) ~/ 3 * 3 + 1;
    return sales.where((s) {
      final d = s.date;
      final c = DateTime(now.year, qMonth);
      return !d.isBefore(c);
    }).toList();
  } else if (range == BiTimeRange.year) {
    return sales.where((s) => s.date.year == now.year).toList();
  }
  final monthStart = DateTime(now.year, now.month, 1);
  return sales.where((s) => !s.date.isBefore(monthStart)).toList();
}

List<ExpenseItem> filterExpensesByTimeRange(
  List<ExpenseItem> expenses,
  BiTimeRange range,
) {
  if (range == BiTimeRange.all) return expenses;
  final now = DateTime.now();
  if (range == BiTimeRange.year) {
    return expenses.where((e) => e.date.year == now.year).toList();
  }
  if (range == BiTimeRange.quarter) {
    final qMonth = (now.month - 1) ~/ 3 * 3 + 1;
    final c = DateTime(now.year, qMonth);
    return expenses.where((e) => !e.date.isBefore(c)).toList();
  }
  final monthStart = DateTime(now.year, now.month, 1);
  return expenses.where((e) => !e.date.isBefore(monthStart)).toList();
}

MomRevenueChange computeMoMRevenueChange(List<SaleTransaction> sales) {
  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final lastMonthStart = DateTime(now.year, now.month - 1, 1);

  var thisMonth = 0.0;
  var lastMonth = 0.0;
  for (final s in sales) {
    final d = s.date;
    if (!d.isBefore(thisMonthStart)) {
      thisMonth += s.total;
    } else if (!d.isBefore(lastMonthStart) && d.isBefore(thisMonthStart)) {
      lastMonth += s.total;
    }
  }

  if (thisMonth == 0 && lastMonth == 0) {
    return const MomRevenueChange(percent: 0, hasData: false, direction: 'flat');
  }
  if (lastMonth == 0) {
    return const MomRevenueChange(percent: 100, hasData: true, direction: 'up');
  }
  final pct = ((thisMonth - lastMonth) / lastMonth * 100).roundToDouble();
  return MomRevenueChange(
    percent: pct.abs(),
    hasData: true,
    direction: pct > 0 ? 'up' : pct < 0 ? 'down' : 'flat',
  );
}

List<CategoryProfitRow> computeCategoryProfitContribution(
  List<Product> products,
  List<SaleTransaction> sales,
) {
  final costById = {for (final p in products) p.id: p.cost};
  final byCat = <String, ({double revenue, double cogs})>{};

  for (final sale in sales) {
    for (final item in sale.items) {
      Product? product;
      for (final p in products) {
        if (p.id == item.productId) {
          product = p;
          break;
        }
      }
      final category = product?.category ?? 'General';
      final revenue = item.total;
      final cogs = (costById[item.productId] ?? 0) * item.quantity;
      final cur = byCat[category] ?? (revenue: 0.0, cogs: 0.0);
      byCat[category] = (revenue: cur.revenue + revenue, cogs: cur.cogs + cogs);
    }
  }

  final rows = byCat.entries.map((e) {
    final profit = e.value.revenue - e.value.cogs;
    final margin = e.value.revenue > 0 ? (profit / e.value.revenue * 100) : 0.0;
    return CategoryProfitRow(
      category: e.key,
      profit: profit,
      marginPercent: (margin * 10).roundToDouble() / 10,
      profitSharePercent: 0,
    );
  }).toList();

  final totalProfit =
      rows.fold<double>(0, (s, r) => s + (r.profit > 0 ? r.profit : 0));
  final denom = totalProfit > 0 ? totalProfit : 1;
  return rows
      .map((r) => CategoryProfitRow(
            category: r.category,
            profit: r.profit,
            marginPercent: r.marginPercent,
            profitSharePercent:
                ((r.profit > 0 ? r.profit : 0) / denom * 1000).roundToDouble() / 10,
          ))
      .toList()
    ..sort((a, b) => b.profit.compareTo(a.profit));
}

List<ProductBiInsight> computeProductInsights(
  List<Product> products,
  List<SaleTransaction> sales,
) {
  final volumeByProduct = <String, ({double qty, double revenue})>{};
  for (final sale in sales) {
    for (final item in sale.items) {
      final cur = volumeByProduct[item.productId] ?? (qty: 0.0, revenue: 0.0);
      volumeByProduct[item.productId] = (
        qty: cur.qty + item.quantity,
        revenue: cur.revenue + item.total,
      );
    }
  }

  final insights = products.map((p) {
    final vol = volumeByProduct[p.id] ?? (qty: 0.0, revenue: 0.0);
    final margin = p.price > 0 ? ((p.price - p.cost) / p.price * 100) : 0.0;
    final grossProfit = vol.qty * (p.price - p.cost);
    var health = 'healthy';
    if (vol.qty == 0 && p.stock > p.reorderPoint * 2) {
      health = 'dead_capital';
    } else if (vol.qty > p.reorderPoint) {
      health = 'fast_mover';
    } else if (p.stock <= p.reorderPoint) {
      health = 'slow_mover';
    }
    return ProductBiInsight(
      productId: p.id,
      productName: p.name,
      category: p.category,
      unitPrice: p.price,
      costPrice: p.cost,
      marginPercent: (margin * 10).roundToDouble() / 10,
      monthlySalesVolume: vol.qty,
      monthlyRevenue: vol.revenue,
      monthlyGrossProfit: grossProfit,
      profitContributionPercent: 0,
      paretoClass: 'C',
      stockHealthStatus: health,
    );
  }).toList();

  final totalProfit =
      insights.fold<double>(0, (s, i) => s + i.monthlyGrossProfit);
  final denom = totalProfit > 0 ? totalProfit : 1;
  final sorted = [...insights]
    ..sort((a, b) => b.monthlyGrossProfit.compareTo(a.monthlyGrossProfit));

  var cumulative = 0.0;
  return sorted.map((i) {
    final share = (i.monthlyGrossProfit / denom * 1000).roundToDouble() / 10;
    cumulative += share;
    final pareto = cumulative <= 80 ? 'A' : cumulative <= 95 ? 'B' : 'C';
    return ProductBiInsight(
      productId: i.productId,
      productName: i.productName,
      category: i.category,
      unitPrice: i.unitPrice,
      costPrice: i.costPrice,
      marginPercent: i.marginPercent,
      monthlySalesVolume: i.monthlySalesVolume,
      monthlyRevenue: i.monthlyRevenue,
      monthlyGrossProfit: i.monthlyGrossProfit,
      profitContributionPercent: share,
      paretoClass: pareto,
      stockHealthStatus: i.stockHealthStatus,
    );
  }).toList();
}

List<MonthlyPlRow> computeMonthlyPlTrend(
  List<SaleTransaction> sales,
  List<Product> products,
  List<ExpenseItem> expenses, {
  int monthCount = 6,
}) {
  final costById = {for (final p in products) p.id: p.cost};
  final buckets = <MonthlyPlRow>[];
  final keys = <String>[];

  for (var i = monthCount - 1; i >= 0; i--) {
    final d = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
    final label = _monthLabel(d.month);
    keys.add('${d.year}-${d.month}');
    buckets.add(MonthlyPlRow(
      month: label,
      revenue: 0,
      cogs: 0,
      opex: 0,
      netProfit: 0,
    ));
  }

  for (final sale in sales) {
    final key = '${sale.date.year}-${sale.date.month}';
    final idx = keys.indexOf(key);
    if (idx < 0) continue;
    final b = buckets[idx];
    final cogs = sale.items.fold<double>(
        0, (s, item) => s + (costById[item.productId] ?? 0) * item.quantity);
    buckets[idx] = MonthlyPlRow(
      month: b.month,
      revenue: b.revenue + sale.total,
      cogs: b.cogs + cogs,
      opex: b.opex,
      netProfit: b.netProfit,
    );
  }

  for (final exp in expenses) {
    final key = '${exp.date.year}-${exp.date.month}';
    final idx = keys.indexOf(key);
    if (idx < 0) continue;
    final b = buckets[idx];
    buckets[idx] = MonthlyPlRow(
      month: b.month,
      revenue: b.revenue,
      cogs: b.cogs,
      opex: b.opex + exp.amount,
      netProfit: b.netProfit,
    );
  }

  return buckets
      .map((b) => MonthlyPlRow(
            month: b.month,
            revenue: b.revenue,
            cogs: b.cogs,
            opex: b.opex,
            netProfit: b.revenue - b.cogs - b.opex,
          ))
      .toList();
}

List<CostSavingOpportunity> buildCostSavingOpportunities(
  List<ProductBiInsight> productInsights,
  List<Product> products,
  List<ExpenseItem> expenses,
  List<Supplier> suppliers,
) {
  final ops = <CostSavingOpportunity>[];
  final stockById = {for (final p in products) p.id: p.stock};

  final deadCapital = productInsights
      .where((p) =>
          p.paretoClass == 'C' &&
          (p.stockHealthStatus == 'dead_capital' || p.monthlySalesVolume == 0))
      .take(2)
      .toList();

  if (deadCapital.isNotEmpty) {
    var locked = 0.0;
    for (final p in deadCapital) {
      locked += p.costPrice * (stockById[p.productId] ?? 0);
    }
    ops.add(CostSavingOpportunity(
      id: 'dead-capital',
      savingsLabel: 'Save up to TSh ${(locked > 50000 ? locked : 50000).round()}',
      tag: 'Dead capital',
      title: 'Discount slow Class C SKUs',
      description:
          '${deadCapital.map((p) => p.productName).join(', ')} have weak turnover. Run a promo to free working capital.',
    ));
  }

  final utilityTotal = expenses
      .where((e) => e.category == 'utilities_luku' || e.category == 'water')
      .fold<double>(0, (s, e) => s + e.amount);
  if (utilityTotal > 0) {
    ops.add(CostSavingOpportunity(
      id: 'utilities',
      savingsLabel: 'Save ~TSh ${(utilityTotal * 0.1).round()} / mo',
      tag: 'Utilities',
      title: 'Trim electricity & water usage',
      description:
          'Current utility spend is TSh ${utilityTotal.round()}. Switch off non-essential loads after hours.',
    ));
  }

  if (suppliers.isNotEmpty) {
    final top = [...suppliers]..sort((a, b) => b.outstandingPayable.compareTo(a.outstandingPayable));
    final s = top.first;
    if (s.outstandingPayable > 0) {
      ops.add(CostSavingOpportunity(
        id: 'supplier-terms',
        savingsLabel: 'Save ~TSh ${(s.outstandingPayable * 0.05).round()}',
        tag: 'Suppliers',
        title: 'Negotiate early payment discount',
        description:
            '${s.name} has TSh ${s.outstandingPayable.round()} payable. Ask for 3–5% early settlement.',
      ));
    }
  }

  if (ops.isEmpty) {
    ops.add(const CostSavingOpportunity(
      id: 'baseline',
      savingsLabel: 'Start recording data',
      tag: 'Guidance',
      title: 'Record sales, expenses, and suppliers',
      description:
          'Once POS sales and shop expenses are recorded, cost-saving opportunities will appear here.',
    ));
  }

  return ops.take(4).toList();
}

String apiRangeFromBiTimeRange(BiTimeRange range) {
  switch (range) {
    case BiTimeRange.quarter:
      return 'quarter';
    case BiTimeRange.year:
      return 'year';
    case BiTimeRange.all:
      return 'all';
    case BiTimeRange.month:
      return 'month';
  }
}

BiSnapshot biSnapshotFromApi(Map<String, dynamic> raw) {
  final mom = raw['mom_change'] as Map<String, dynamic>? ?? {};
  return BiSnapshot(
    grossSales: (raw['gross_sales'] as num?)?.toDouble() ?? 0,
    cogs: (raw['cogs'] as num?)?.toDouble() ?? 0,
    grossMargin: (raw['gross_margin'] as num?)?.toDouble() ?? 0,
    totalOpex: (raw['total_opex'] as num?)?.toDouble() ?? 0,
    netProfit: (raw['net_profit'] as num?)?.toDouble() ?? 0,
    momChange: MomRevenueChange(
      percent: (mom['percent'] as num?)?.toDouble() ?? 0,
      hasData: mom['has_data'] == true,
      direction: mom['direction']?.toString() ?? 'flat',
    ),
    categoryProfits: ((raw['category_profits'] as List?) ?? [])
        .map((r) => CategoryProfitRow(
              category: r['category']?.toString() ?? '',
              profit: (r['profit'] as num?)?.toDouble() ?? 0,
              marginPercent: (r['margin_percent'] as num?)?.toDouble() ?? 0,
              profitSharePercent: (r['profit_share_percent'] as num?)?.toDouble() ?? 0,
            ))
        .toList(),
    monthlyPl: ((raw['monthly_pl'] as List?) ?? [])
        .map((r) => MonthlyPlRow(
              month: r['month']?.toString() ?? '',
              revenue: (r['revenue'] as num?)?.toDouble() ?? 0,
              cogs: (r['cogs'] as num?)?.toDouble() ?? 0,
              opex: (r['opex'] as num?)?.toDouble() ?? 0,
              netProfit: (r['net_profit'] as num?)?.toDouble() ?? 0,
            ))
        .toList(),
    topProducts: ((raw['top_products'] as List?) ?? [])
        .map((p) => ProductBiInsight(
              productId: p['product_id']?.toString() ?? '',
              productName: p['product_name']?.toString() ?? '',
              category: p['category']?.toString() ?? '',
              unitPrice: (p['unit_price'] as num?)?.toDouble() ?? 0,
              costPrice: (p['cost_price'] as num?)?.toDouble() ?? 0,
              marginPercent: (p['margin_percent'] as num?)?.toDouble() ?? 0,
              monthlySalesVolume: (p['monthly_sales_volume'] as num?)?.toDouble() ?? 0,
              monthlyRevenue: (p['monthly_revenue'] as num?)?.toDouble() ?? 0,
              monthlyGrossProfit: (p['monthly_gross_profit'] as num?)?.toDouble() ?? 0,
              profitContributionPercent: (p['profit_contribution_percent'] as num?)?.toDouble() ?? 0,
              paretoClass: p['pareto_class']?.toString() ?? 'C',
              stockHealthStatus: p['stock_health_status']?.toString() ?? 'ok',
            ))
        .toList(),
    costSavings: ((raw['cost_savings'] as List?) ?? [])
        .map((c) => CostSavingOpportunity(
              id: c['id']?.toString() ?? '',
              savingsLabel: c['savings_label']?.toString() ?? '',
              tag: c['tag']?.toString() ?? '',
              title: c['title']?.toString() ?? '',
              description: c['description']?.toString() ?? '',
            ))
        .toList(),
  );
}

BiSnapshot buildBiSnapshot({
  required List<SaleTransaction> sales,
  required List<Product> products,
  required List<ExpenseItem> expenses,
  required List<Supplier> suppliers,
  BiTimeRange range = BiTimeRange.month,
}) {
  final scopedSales = filterSalesByTimeRange(sales, range);
  final scopedExpenses = filterExpensesByTimeRange(expenses, range);

  final grossSales = scopedSales.fold<double>(0, (s, x) => s + x.total);
  final costById = {for (final p in products) p.id: p.cost};
  var cogs = 0.0;
  for (final sale in scopedSales) {
    for (final item in sale.items) {
      cogs += (costById[item.productId] ?? 0) * item.quantity;
    }
  }
  final totalOpex = scopedExpenses.fold<double>(0, (s, e) => s + e.amount);
  final grossMargin = grossSales - cogs;
  final netProfit = grossMargin - totalOpex;

  final productInsights = computeProductInsights(products, scopedSales);

  return BiSnapshot(
    grossSales: grossSales,
    cogs: cogs,
    grossMargin: grossMargin,
    totalOpex: totalOpex,
    netProfit: netProfit,
    momChange: computeMoMRevenueChange(sales),
    categoryProfits: computeCategoryProfitContribution(products, scopedSales),
    monthlyPl: computeMonthlyPlTrend(sales, products, expenses),
    topProducts: productInsights.take(8).toList(),
    costSavings: buildCostSavingOpportunities(
      productInsights,
      products,
      scopedExpenses,
      suppliers,
    ),
  );
}

String _monthLabel(int month) {
  const labels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return labels[(month - 1).clamp(0, 11)];
}
