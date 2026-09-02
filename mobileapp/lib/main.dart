import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  // ── Portrait lock (real-device feel like WhatsApp / banking apps) ──────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Transparent status bar with light icons ────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                    Colors.transparent,
    statusBarIconBrightness:           Brightness.light,
    statusBarBrightness:               Brightness.dark, // iOS
    systemNavigationBarColor:          Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor:   Colors.transparent,
  ));

  // ── Ensure system navigation bar is drawn edge-to-edge ────────────────
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const ProviderScope(child: DukaApp()));
}

class DukaApp extends ConsumerWidget {
  const DukaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router  = ref.watch(appRouterProvider);
    final bizType = ref.watch(businessTypeProvider);
    final locale  = ref.watch(localeProvider);

    return MaterialApp.router(
      title:                      'DukaPlus+',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.light(businessType: bizType),
      locale:                     locale.l10n.locale,
      supportedLocales: const [
        Locale('sw'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // ── Builder: enforce proper text scaling & edge-to-edge ──────────
      builder: (context, child) {
        // Prevent system font size from breaking layouts (accessibility handled
        // by our own adaptive sizing)
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Cap text scale at 1.2 — prevents overflow on small screens
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
