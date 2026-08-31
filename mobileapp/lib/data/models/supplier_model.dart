import 'package:flutter/foundation.dart';

@immutable
class Supplier {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String category;
  final String paymentTerms;
  final double outstandingPayable;
  final int leadTimeDays;
  final double rating;
  final double balance;
  final double totalPurchases;

  const Supplier({
    required this.id,
    required this.name,
    this.contactPerson = '',
    this.phone = '',
    this.email = '',
    this.category = '',
    this.paymentTerms = 'Net 30 Days',
    this.outstandingPayable = 0,
    this.leadTimeDays = 7,
    this.rating = 0,
    this.balance = 0,
    this.totalPurchases = 0,
  });

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
    id:                  j['id']?.toString() ?? '',
    name:                j['name']?.toString() ?? '',
    contactPerson:       j['contact_person']?.toString() ?? '',
    phone:               j['phone']?.toString() ?? '',
    email:               j['email']?.toString() ?? '',
    category:            j['category']?.toString() ?? '',
    paymentTerms:        j['payment_terms']?.toString() ?? 'Net 30 Days',
    outstandingPayable:  _d(j['outstanding_payable']),
    leadTimeDays:        _i(j['lead_time_days']),
    rating:              _d(j['rating']),
    balance:             _d(j['balance']),
    totalPurchases:      _d(j['total_purchases']),
  );

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
  }

  static double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
  static int    _i(dynamic v) => v == null ? 0   : int.tryParse(v.toString())    ?? 0;
}
