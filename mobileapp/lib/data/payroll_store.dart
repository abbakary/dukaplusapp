import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StaffPayrollConfig {
  final double? baseSalary;
  final double? dailyFoodAllowance;
  final double? dailyTransportAllowance;

  const StaffPayrollConfig({this.baseSalary, this.dailyFoodAllowance, this.dailyTransportAllowance});

  Map<String, dynamic> toJson() => {
    if (baseSalary != null) 'baseSalary': baseSalary,
    if (dailyFoodAllowance != null) 'dailyFoodAllowance': dailyFoodAllowance,
    if (dailyTransportAllowance != null) 'dailyTransportAllowance': dailyTransportAllowance,
  };

  factory StaffPayrollConfig.fromJson(Map<String, dynamic> j) => StaffPayrollConfig(
    baseSalary: _d(j['baseSalary']),
    dailyFoodAllowance: _d(j['dailyFoodAllowance']),
    dailyTransportAllowance: _d(j['dailyTransportAllowance']),
  );

  static double? _d(dynamic v) => v == null ? null : double.tryParse(v.toString());
}

class DailyAllowanceRecord {
  final String id;
  final String date;
  final String staffId;
  final String staffName;
  final double foodAmount;
  final double transportAmount;
  final double totalAmount;
  final String status;

  const DailyAllowanceRecord({
    required this.id,
    required this.date,
    required this.staffId,
    required this.staffName,
    required this.foodAmount,
    required this.transportAmount,
    required this.totalAmount,
    this.status = 'claimed',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date, 'staffId': staffId, 'staffName': staffName,
    'foodAmount': foodAmount, 'transportAmount': transportAmount,
    'totalAmount': totalAmount, 'status': status,
  };

  factory DailyAllowanceRecord.fromJson(Map<String, dynamic> j) => DailyAllowanceRecord(
    id: j['id']?.toString() ?? '',
    date: j['date']?.toString() ?? '',
    staffId: j['staffId']?.toString() ?? '',
    staffName: j['staffName']?.toString() ?? '',
    foodAmount: double.tryParse(j['foodAmount']?.toString() ?? '0') ?? 0,
    transportAmount: double.tryParse(j['transportAmount']?.toString() ?? '0') ?? 0,
    totalAmount: double.tryParse(j['totalAmount']?.toString() ?? '0') ?? 0,
    status: j['status']?.toString() ?? 'claimed',
  );
}

class PayrollRecord {
  final String id;
  final String monthYear;
  final String staffId;
  final String staffName;
  final double netPayable;
  final String status;

  const PayrollRecord({
    required this.id,
    required this.monthYear,
    required this.staffId,
    required this.staffName,
    required this.netPayable,
    this.status = 'paid',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'monthYear': monthYear, 'staffId': staffId,
    'staffName': staffName, 'netPayable': netPayable, 'status': status,
  };

  factory PayrollRecord.fromJson(Map<String, dynamic> j) => PayrollRecord(
    id: j['id']?.toString() ?? '',
    monthYear: j['monthYear']?.toString() ?? '',
    staffId: j['staffId']?.toString() ?? '',
    staffName: j['staffName']?.toString() ?? '',
    netPayable: double.tryParse(j['netPayable']?.toString() ?? '0') ?? 0,
    status: j['status']?.toString() ?? 'paid',
  );
}

class PayrollStoreData {
  final List<DailyAllowanceRecord> dailyAllowances;
  final List<PayrollRecord> payrollRecords;
  final Map<String, StaffPayrollConfig> staffConfig;

  const PayrollStoreData({
    this.dailyAllowances = const [],
    this.payrollRecords = const [],
    this.staffConfig = const {},
  });

  PayrollStoreData copyWith({
    List<DailyAllowanceRecord>? dailyAllowances,
    List<PayrollRecord>? payrollRecords,
    Map<String, StaffPayrollConfig>? staffConfig,
  }) => PayrollStoreData(
    dailyAllowances: dailyAllowances ?? this.dailyAllowances,
    payrollRecords: payrollRecords ?? this.payrollRecords,
    staffConfig: staffConfig ?? this.staffConfig,
  );
}

class PayrollStore {
  static String _key(String tenantId) => 'dukamkononi_payroll_$tenantId';

  static String todayDateStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String currentMonthStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  static Future<PayrollStoreData> load(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(tenantId));
    if (raw == null) return const PayrollStoreData();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final cfgRaw = j['staffConfig'] as Map<String, dynamic>? ?? {};
      return PayrollStoreData(
        dailyAllowances: (j['dailyAllowances'] as List? ?? [])
            .map((e) => DailyAllowanceRecord.fromJson(e as Map<String, dynamic>)).toList(),
        payrollRecords: (j['payrollRecords'] as List? ?? [])
            .map((e) => PayrollRecord.fromJson(e as Map<String, dynamic>)).toList(),
        staffConfig: cfgRaw.map((k, v) => MapEntry(k, StaffPayrollConfig.fromJson(v as Map<String, dynamic>))),
      );
    } catch (_) {
      return const PayrollStoreData();
    }
  }

  static Future<void> save(String tenantId, PayrollStoreData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(tenantId), jsonEncode({
      'dailyAllowances': data.dailyAllowances.map((e) => e.toJson()).toList(),
      'payrollRecords': data.payrollRecords.map((e) => e.toJson()).toList(),
      'staffConfig': data.staffConfig.map((k, v) => MapEntry(k, v.toJson())),
    }));
  }

  static double monthAllowancesTotal(String staffId, String month, List<DailyAllowanceRecord> list) {
    return list
        .where((a) => a.staffId == staffId && a.date.startsWith(month) && a.status == 'claimed')
        .fold(0.0, (s, a) => s + a.totalAmount);
  }

  static DailyAllowanceRecord? findTodayClaim(String staffId, String date, List<DailyAllowanceRecord> list) {
    try {
      return list.firstWhere((a) => a.staffId == staffId && a.date == date && a.status == 'claimed');
    } catch (_) {
      return null;
    }
  }
}
