import 'package:flutter/foundation.dart';

enum LoyaltyTier { bronze, silver, gold }
enum RiskScore { low, medium, high }

LoyaltyTier loyaltyFromString(String? s) {
  switch (s?.toLowerCase()) {
    case 'silver': return LoyaltyTier.silver;
    case 'gold':   return LoyaltyTier.gold;
    default:       return LoyaltyTier.bronze;
  }
}

RiskScore riskFromString(String? s) {
  switch (s?.toLowerCase()) {
    case 'medium': return RiskScore.medium;
    case 'high':   return RiskScore.high;
    default:       return RiskScore.low;
  }
}

String loyaltyTierLabel(LoyaltyTier tier) {
  switch (tier) {
    case LoyaltyTier.gold:
      return 'GOLD';
    case LoyaltyTier.silver:
      return 'SILVER';
    case LoyaltyTier.bronze:
      return 'BRONZE';
  }
}

@immutable
class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double creditLimit;
  final double balance;
  final DateTime? joinedDate;
  final LoyaltyTier loyaltyTier;
  final int loyaltyPoints;
  final RiskScore riskScore;
  final String dunningStage;
  final int daysOverdue;
  final DateTime? lastPurchaseDate;
  final double totalPurchases;
  final String avatarColor;
  final String? notes;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.creditLimit = 0,
    this.balance = 0,
    this.joinedDate,
    this.loyaltyTier = LoyaltyTier.bronze,
    this.loyaltyPoints = 0,
    this.riskScore = RiskScore.low,
    this.dunningStage = 'cleared',
    this.daysOverdue = 0,
    this.lastPurchaseDate,
    this.totalPurchases = 0,
    this.avatarColor = '#1A3A6B',
    this.notes,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
    id:              j['id']?.toString() ?? '',
    name:            j['name']?.toString() ?? '',
    phone:           j['phone']?.toString() ?? '',
    email:           j['email']?.toString() ?? '',
    address:         j['address']?.toString() ?? '',
    creditLimit:     _d(j['credit_limit']),
    balance:         _d(j['balance']),
    joinedDate:      j['joined_date'] != null ? DateTime.tryParse(j['joined_date'].toString()) : null,
    loyaltyTier:     loyaltyFromString(j['loyalty_tier']?.toString()),
    loyaltyPoints:   _i(j['loyalty_points']),
    riskScore:       riskFromString(j['risk_score']?.toString()),
    dunningStage:    j['dunning_stage']?.toString() ?? 'cleared',
    daysOverdue:     _i(j['days_overdue']),
    lastPurchaseDate: j['last_purchase_date'] != null
        ? DateTime.tryParse(j['last_purchase_date'].toString()) : null,
    totalPurchases:  _d(j['total_purchases']),
    avatarColor:     j['avatar_color']?.toString() ?? '#1A3A6B',
    notes:           j['notes']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'email': email,
    'address': address, 'credit_limit': creditLimit,
    'notes': notes,
  };

  bool get hasDebt => balance > 0;
  bool get isOverdue => daysOverdue > 0;
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
  static int    _i(dynamic v) => v == null ? 0   : int.tryParse(v.toString())    ?? 0;
}
