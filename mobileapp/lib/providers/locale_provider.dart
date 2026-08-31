import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../l10n/app_localizations.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  return ref.watch(localeProvider).l10n;
});

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.sw) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(AppConstants.kLanguage);
    state = code == 'en' ? AppLanguage.en : AppLanguage.sw;
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kLanguage, lang == AppLanguage.en ? 'en' : 'sw');
  }
}
