import 'package:flutter/foundation.dart';

@immutable
class DashboardStats {
  final double todayRevenue;
  final int todaySalesCount;
  final double weekRevenue;
  final double monthRevenue;
  final int lowStockCount;
  final int expiringCount;
  final double totalReceivables;
  final double totalPayables;
  final int totalCustomers;
  final int pendingOrders;
  final double stockValue;
  final List<RevenuePoint> revenueTrend;
  final Map<String, double> paymentBreakdown;
  final List<TopProduct> topProducts;

  const DashboardStats({
    this.todayRevenue = 0,
    this.todaySalesCount = 0,
    this.weekRevenue = 0,
    this.monthRevenue = 0,
    this.lowStockCount = 0,
    this.expiringCount = 0,
    this.totalReceivables = 0,
    this.totalPayables = 0,
    this.totalCustomers = 0,
    this.pendingOrders = 0,
    this.stockValue = 0,
    this.revenueTrend = const [],
    this.paymentBreakdown = const {},
    this.topProducts = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    todayRevenue:     _d(j['today_revenue']),
    todaySalesCount:  _i(j['today_sales_count']),
    weekRevenue:      _d(j['week_revenue']),
    monthRevenue:     _d(j['month_revenue'] ?? j['monthly_revenue']),
    lowStockCount:    _i(j['low_stock_count']),
    expiringCount:    _i(j['expiring_count'] ?? j['expiring_soon_count']),
    totalReceivables: _d(j['total_receivables'] ?? j['outstanding_receivables']),
    totalPayables:    _d(j['total_payables'] ?? j['outstanding_payables']),
    totalCustomers:   _i(j['total_customers']),
    pendingOrders:    _i(j['pending_orders']),
    stockValue:       _d(j['stock_value']),
    revenueTrend:     (j['revenue_trend'] as List? ?? []).map((e) => RevenuePoint.fromJson(e as Map<String, dynamic>)).toList(),
    paymentBreakdown: (j['payment_breakdown'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, _d(v))),
    topProducts:      (j['top_products'] as List? ?? []).map((e) => TopProduct.fromJson(e as Map<String, dynamic>)).toList(),
  );

  DashboardStats copyWith({List<TopProduct>? topProducts}) => DashboardStats(
    todayRevenue: todayRevenue,
    todaySalesCount: todaySalesCount,
    weekRevenue: weekRevenue,
    monthRevenue: monthRevenue,
    lowStockCount: lowStockCount,
    expiringCount: expiringCount,
    totalReceivables: totalReceivables,
    totalPayables: totalPayables,
    totalCustomers: totalCustomers,
    pendingOrders: pendingOrders,
    stockValue: stockValue,
    revenueTrend: revenueTrend,
    paymentBreakdown: paymentBreakdown,
    topProducts: topProducts ?? this.topProducts,
  );

  static double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
  static int    _i(dynamic v) => v == null ? 0   : int.tryParse(v.toString())    ?? 0;

  // Fallback demo data for when API has no stats yet
  static DashboardStats demo() => DashboardStats(
    todayRevenue: 450000,
    todaySalesCount: 28,
    weekRevenue: 2800000,
    monthRevenue: 11500000,
    lowStockCount: 5,
    expiringCount: 3,
    totalReceivables: 850000,
    totalPayables: 320000,
    totalCustomers: 142,
    pendingOrders: 4,
    stockValue: 18500000,
    revenueTrend: List.generate(7, (i) => RevenuePoint(
      label: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
      revenue: [320000, 450000, 380000, 520000, 610000, 780000, 450000][i].toDouble(),
    )),
    paymentBreakdown: {
      'cash': 180000, 'mpesa': 160000, 'airtel': 60000,
      'tigopesa': 30000, 'card': 20000,
    },
    topProducts: [
      TopProduct(name: 'Product A', revenue: 120000, quantity: 45),
      TopProduct(name: 'Product B', revenue: 98000,  quantity: 32),
      TopProduct(name: 'Product C', revenue: 76000,  quantity: 28),
      TopProduct(name: 'Product D', revenue: 62000,  quantity: 24),
    ],
  );
}

@immutable
class RevenuePoint {
  final String label;
  final double revenue;
  const RevenuePoint({required this.label, required this.revenue});
  factory RevenuePoint.fromJson(Map<String, dynamic> j) => RevenuePoint(
    label:   j['label']?.toString() ?? '',
    revenue: double.tryParse(j['revenue']?.toString() ?? '0') ?? 0,
  );
}

@immutable
class TopProduct {
  final String id;
  final String name;
  final double revenue;
  final int quantity;
  const TopProduct({
    this.id = '',
    required this.name,
    required this.revenue,
    required this.quantity,
  });

  factory TopProduct.fromJson(Map<String, dynamic> j) {
    final qtyRaw = j['quantity'] ?? j['monthly_sales_volume'] ?? j['qty'] ?? j['units_sold'] ?? 0;
    final revRaw = j['revenue'] ?? j['monthly_revenue'] ?? j['total_revenue'] ?? j['amount'] ?? 0;
    final nameRaw = j['name'] ?? j['product_name'] ?? j['productName'] ?? j['title'] ?? '';
    return TopProduct(
      id: j['product_id']?.toString() ?? j['id']?.toString() ?? '',
      name: nameRaw.toString().trim(),
      revenue: _d(revRaw),
      quantity: _i(qtyRaw),
    );
  }

  bool get isComplete => name.isNotEmpty && (revenue > 0 || quantity > 0);

  static double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
  static int _i(dynamic v) => v == null ? 0 : (double.tryParse(v.toString()) ?? 0).round();
}
