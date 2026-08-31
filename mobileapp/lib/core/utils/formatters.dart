import 'package:intl/intl.dart';

class AppFormatters {
  static final _tsh    = NumberFormat('#,##0', 'en_US');
  static final _tshDec = NumberFormat('#,##0.00', 'en_US');
  static final _date   = DateFormat('dd MMM yyyy');
  static final _time   = DateFormat('HH:mm');
  static final _dt     = DateFormat('dd MMM yyyy, HH:mm');
  static final _short  = DateFormat('dd/MM/yy');

  /// e.g. TSh 1,250,000
  static String tsh(num amount) => 'TSh ${_tsh.format(amount)}';

  /// e.g. TSh 1,250,000.50
  static String tshDec(num amount) => 'TSh ${_tshDec.format(amount)}';

  /// e.g. 12,500
  static String number(num v) => _tsh.format(v);

  /// e.g. 14 Sep 2026
  static String date(DateTime d) => _date.format(d);

  /// e.g. 14 Sep 2026 or "—" if null
  static String dateOr(DateTime? d) => d == null ? '—' : _date.format(d);

  /// e.g. 09:35
  static String time(DateTime d) => _time.format(d);

  /// e.g. 14 Sep 2026, 09:35
  static String dateTime(DateTime d) => _dt.format(d);

  /// e.g. 14/09/26
  static String shortDate(DateTime d) => _short.format(d);

  /// Today / Yesterday / date
  static String relativeDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return _date.format(d);
  }

  /// e.g. "#QT1025"
  static String receiptNo(String s) => '#$s';

  /// Compact thousands e.g. 1.2M, 450K
  static String compact(num v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return _tsh.format(v);
  }

  /// Percentage
  static String pct(double v) => '${v.toStringAsFixed(1)}%';
}
