import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/business_settings.dart';
import '../data/services/api_client.dart';
import '../data/models/user_model.dart';
import 'auth_provider.dart';
import 'api_provider.dart';

class BusinessSettingsNotifier extends StateNotifier<BusinessSettings> {
  BusinessSettingsNotifier(this._tenantKey, this._api) : super(const BusinessSettings()) {
    _load();
    syncFromApi();
  }

  final String _tenantKey;
  final ApiClient _api;
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

  Future<void> syncFromApi() async {
    try {
      final data = await _api.getTenantSettings();
      final raw = data['business_settings'];
      if (raw is Map<String, dynamic>) {
        await update(BusinessSettings.fromJson(raw));
      }
    } catch (_) {
      // Keep cached/local settings when offline
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
    bool? cartDiscountEnabled,
    bool? priceOverrideEnabled,
    bool? partialPaymentEnabled,
    bool? negotiationEnabled,
    bool? vatEnabled,
    double? vatRate,
  }) =>
      update(state.copyWith(
        discountEnabled: discountEnabled,
        maxDiscountPercent: maxDiscountPercent,
        showDiscountOnReceipts: showDiscountOnReceipts,
        showDiscountOnDocuments: showDiscountOnDocuments,
        cartDiscountEnabled: cartDiscountEnabled,
        priceOverrideEnabled: priceOverrideEnabled,
        partialPaymentEnabled: partialPaymentEnabled,
        negotiationEnabled: negotiationEnabled,
        vatEnabled: vatEnabled,
        vatRate: vatRate,
      ));
}

final businessSettingsProvider =
    StateNotifierProvider<BusinessSettingsNotifier, BusinessSettings>((ref) {
  final user = ref.watch(currentUserProvider);
  final key = user?.email ?? user?.id ?? 'default';
  final api = ref.read(apiClientProvider);
  final notifier = BusinessSettingsNotifier(key, api);
  ref.listen<AuthUser?>(currentUserProvider, (prev, next) {
    if (next != null && next.id != prev?.id) {
      notifier.syncFromApi();
    }
  });
  return notifier;
});
