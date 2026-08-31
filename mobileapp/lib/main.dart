import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: DukaApp()));
}

class DukaApp extends ConsumerWidget {
  const DukaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router      = ref.watch(appRouterProvider);
    final bizType     = ref.watch(businessTypeProvider);
    final locale      = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Duka+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(businessType: bizType),
      locale: locale.l10n.locale,
      supportedLocales: const [Locale('sw'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
