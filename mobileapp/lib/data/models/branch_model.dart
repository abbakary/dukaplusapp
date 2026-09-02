import 'package:flutter/foundation.dart';

enum BranchType   { mainHq, subBranch, warehouse }
enum BranchStatus { active, inactive, renovation, closed }

@immutable
class StoreBranch {
  final String id;
  final String name;
  final String code;
  final BranchType type;
  final BranchStatus status;
  final String region;
  final String district;
  final String address;
  final String phone;
  final String? managerName;
  final int staffCount;
  final double dailyGmvTzs;
  final double monthlyGmvTzs;
  final int stockCount;
  final double stockValuationTzs;
  final String traEfdSerial;
  final String openingHours;

  const StoreBranch({
    required this.id,
    required this.name,
    required this.code,
    this.type = BranchType.subBranch,
    this.status = BranchStatus.active,
    this.region = '',
    this.district = '',
    this.address = '',
    this.phone = '',
    this.managerName,
    this.staffCount = 0,
    this.dailyGmvTzs = 0,
    this.monthlyGmvTzs = 0,
    this.stockCount = 0,
    this.stockValuationTzs = 0,
    this.traEfdSerial = '',
    this.openingHours = '08:00 - 20:00',
  });

  factory StoreBranch.fromJson(Map<String, dynamic> j) => StoreBranch(
    id:               j['id']?.toString() ?? '',
    name:             j['name']?.toString() ?? '',
    code:             j['code']?.toString() ?? '',
    type:             _btype(j['branch_type']?.toString() ?? j['type']?.toString()),
    status:           _bstatus(j['status']?.toString()),
    region:           j['region']?.toString() ?? '',
    district:         j['district']?.toString() ?? '',
    address:          j['address']?.toString() ?? '',
    phone:            j['phone']?.toString() ?? '',
    managerName:      j['manager_name']?.toString(),
    staffCount:       _i(j['staff_count']),
    dailyGmvTzs:      _d(j['daily_gmv_tzs']),
    monthlyGmvTzs:    _d(j['monthly_gmv_tzs']),
    stockCount:       _i(j['stock_count']),
    stockValuationTzs: _d(j['stock_valuation_tzs']),
    traEfdSerial:     j['tra_efd_serial']?.toString() ?? '',
    openingHours:     j['opening_hours']?.toString() ?? '08:00 - 20:00',
  );

  static BranchType _btype(String? s) {
    switch (s) { case 'main_hq': return BranchType.mainHq; case 'warehouse': return BranchType.warehouse; default: return BranchType.subBranch; }
  }
  static BranchStatus _bstatus(String? s) {
    switch (s) { case 'inactive': return BranchStatus.inactive; case 'renovation': return BranchStatus.renovation; case 'closed': return BranchStatus.closed; default: return BranchStatus.active; }
  }
  static double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
  static int    _i(dynamic v) => v == null ? 0   : int.tryParse(v.toString())    ?? 0;
}
