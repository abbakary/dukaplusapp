import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/formatters.dart';
import '../l10n/app_localizations.dart';
import 'auth_provider.dart';
import 'dashboard_provider.dart';
import 'locale_provider.dart';
import 'products_provider.dart';

class AiChatState {
  final bool isOpen;
  final String? pendingPrompt;

  const AiChatState({this.isOpen = false, this.pendingPrompt});

  AiChatState copyWith({bool? isOpen, String? pendingPrompt, bool clearPrompt = false}) =>
      AiChatState(
        isOpen: isOpen ?? this.isOpen,
        pendingPrompt: clearPrompt ? null : (pendingPrompt ?? this.pendingPrompt),
      );
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  AiChatNotifier() : super(const AiChatState());

  void open({String? prompt}) =>
      state = AiChatState(isOpen: true, pendingPrompt: prompt);

  void close() => state = const AiChatState(isOpen: false);

  void consumePrompt() {
    if (state.pendingPrompt != null) {
      state = state.copyWith(clearPrompt: true);
    }
  }
}

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) => AiChatNotifier());

/// Builds shop context payload for the AI chat endpoint from live app data.
Future<Map<String, dynamic>> buildAiShopContext(WidgetRef ref) async {
  final user = ref.read(currentUserProvider);
  final stats = ref.read(refreshedDashboardProvider).valueOrNull;
  var productCount = 0;

  try {
    final products = await ref.read(productsProvider.future)
        .timeout(const Duration(seconds: 5));
    productCount = products.length;
  } catch (_) {}

  return {
    'shopName': user?.businessName ?? 'My Store',
    'type': user?.businessType ?? 'retail',
    'revenueToday': AppFormatters.tsh(stats?.todayRevenue ?? 0),
    'activeCustomers': stats?.totalCustomers ?? 0,
    'customerCount': stats?.totalCustomers ?? 0,
    'lowStockCount': stats?.lowStockCount ?? 0,
    'salesCount': stats?.todaySalesCount ?? 0,
    'productCount': productCount,
    'location': 'Tanzania',
  };
}

String aiLanguageCode(WidgetRef ref) =>
    ref.read(localeProvider) == AppLanguage.en ? 'en' : 'sw';
