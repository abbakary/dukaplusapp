import 'package:flutter/foundation.dart';

@immutable
class ExpenseItem {
  final String id;
  final DateTime date;
  final String title;
  final String category;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String recipient;
  final String recordedBy;
  final String status; // paid | pending | reconciled

  const ExpenseItem({
    required this.id,
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    required this.recipient,
    required this.recordedBy,
    this.status = 'paid',
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> j) => ExpenseItem(
    id:              j['id']?.toString() ?? '',
    date:            j['date'] != null ? DateTime.tryParse(j['date'].toString()) ?? DateTime.now() : DateTime.now(),
    title:           j['title']?.toString() ?? '',
    category:        j['category']?.toString() ?? 'other',
    amount:          double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
    paymentMethod:   j['payment_method']?.toString() ?? 'cash_drawer',
    referenceNumber: j['reference_number']?.toString(),
    recipient:       j['recipient']?.toString() ?? '',
    recordedBy:      j['recorded_by']?.toString() ?? '',
    status:          j['status']?.toString() ?? 'paid',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'title': title,
    'category': category, 'amount': amount, 'payment_method': paymentMethod,
    'reference_number': referenceNumber, 'recipient': recipient,
    'recorded_by': recordedBy, 'status': status,
  };

  static const Map<String, String> categoryLabels = {
    'rent':                        'Rent',
    'utilities_luku':              'Electricity (LUKU)',
    'water':                       'Water',
    'staff_salaries':              'Staff Salaries',
    'daily_stipends_food_transport': 'Food & Transport',
    'licenses_permits_brela_tmda': 'Licenses & Permits',
    'marketing_sms':               'Marketing & SMS',
    'maintenance_repairs':         'Maintenance & Repairs',
    'supplier_settlements':        'Supplier Payments',
    'petty_cash':                  'Petty Cash',
    'taxes_tra_local':             'Taxes (TRA/Local)',
    'equipment_assets':            'Equipment & Assets',
    'cleaning_sanitation':         'Cleaning & Sanitation',
    'other':                       'Other',
  };
}
