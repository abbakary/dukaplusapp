import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/business_settings.dart';
import 'auth_provider.dart';

class BusinessSettingsNotifier extends StateNotifier<BusinessSettings> {
  BusinessSettingsNotifier(this._tenantKey) : super(const BusinessSettings()) {
    _load();
  }

  final String _tenantKey;
  static const _prefix = 'duka_business_settings_';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$_tenantKey');
    if (raw != null) {
      try {
        state = BusinessSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
  }

  Future<void> update(BusinessSettings next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$_tenantKey', jsonEncode(next.toJson()));
  }

  Future<void> patch({
    bool? discountEnabled,
    double? maxDiscountPercent,
    bool? showDiscountOnReceipts,
    bool? showDiscountOnDocuments,
    bool? vatEnabled,
    double? vatRate,
  }) =>
      update(state.copyWith(
        discountEnabled: discountEnabled,
        maxDiscountPercent: maxDiscountPercent,
        showDiscountOnReceipts: showDiscountOnReceipts,
        showDiscountOnDocuments: showDiscountOnDocuments,
        vatEnabled: vatEnabled,
        vatRate: vatRate,
      ));
}

final businessSettingsProvider =
    StateNotifierProvider<BusinessSettingsNotifier, BusinessSettings>((ref) {
  final user = ref.watch(currentUserProvider);
  final key = user?.email ?? user?.id ?? 'default';
  return BusinessSettingsNotifier(key);
});
