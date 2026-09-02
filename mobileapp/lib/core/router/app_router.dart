import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/pos/pos_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/customers/customers_screen.dart';
import '../../screens/suppliers/suppliers_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/branches/branches_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/document_templates_screen.dart';
import '../../widgets/main_shell.dart';
import '../../providers/permissions_provider.dart';
import '../../screens/welcome/welcome_screen.dart';
import '../../screens/credit/receivables_payables_screen.dart';
import '../../widgets/stipend_claim_banner.dart';
import '../../screens/pending/pending_transactions_screen.dart';
import '../../screens/legal/terms_of_service_screen.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_brand_logo.dart';
import '../../screens/transactions/transaction_history_screen.dart';
import '../../screens/bi/bi_analytics_screen.dart';

final _rootNavigatorKey  = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Re-runs [GoRouter.redirect] without recreating the router (avoids GlobalKey clashes).
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(authProvider, (_, __) => refresh.ping());
  ref.listen(roleAccessProvider, (_, __) => refresh.ping());

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refresh,
    initialLocation: '/dashboard',
    debugLogDiagnostics: false,

    // ── Redirect logic ─────────────────────────────────────────────────────
    redirect: (context, state) {
      final isInitialising = ref.read(authProvider.select((s) => s.isInitialising));
      final isAuthenticated = ref.read(authProvider.select((s) => s.isAuthenticated));
      final access = ref.read(roleAccessProvider);

      if (isInitialising) return '/splash';

      final loc     = state.matchedLocation;
      final isOnAuth = loc == '/login' || loc == '/register' || loc == '/splash' || loc == '/welcome' || loc == '/terms';

      if (!isAuthenticated && !isOnAuth) return '/welcome';

      if (isAuthenticated) {
        final landing = access?.defaultLandingPath() ?? '/dashboard';
        if (isOnAuth || loc == '/welcome') return landing;
        if (access != null && !access.canAccessPath(loc)) return landing;
      }
      return null;
    },

    routes: [
      // ── Splash (shown only while isInitialising) ───────────────────────
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _SplashScreen(),
      ),

      // ── Public ────────────────────────────────────────────────────────
      GoRoute(path: '/welcome',  builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/terms',    builder: (_, __) => const TermsOfServiceScreen()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // ── Authenticated shell with bottom nav ───────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/pos',       builder: (_, __) => const PosScreen()),
          GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
          GoRoute(path: '/customers', builder: (_, __) => const CustomersScreen()),
          GoRoute(path: '/suppliers', builder: (_, __) => const SuppliersScreen()),
          GoRoute(path: '/credit',   builder: (_, __) => const ReceivablesPayablesScreen()),
          GoRoute(path: '/reports',   builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/transactions', builder: (_, __) => const TransactionHistoryScreen()),
          GoRoute(path: '/documents', builder: (_, __) => const DocumentTemplatesScreen()),
          GoRoute(path: '/bi',        builder: (_, __) => const BiAnalyticsScreen()),
          GoRoute(path: '/branches',  builder: (_, __) => const BranchesScreen()),
          GoRoute(path: '/expenses',  builder: (_, __) => const ExpensesScreen()),
          GoRoute(path: '/my-stipend', builder: (_, __) => const MyStipendScreen()),
          GoRoute(path: '/pending',   builder: (_, __) => const PendingTransactionsScreen()),
          GoRoute(path: '/settings',  builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/settings/documents', builder: (_, __) => const DocumentTemplatesScreen()),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

// ── Minimal animated splash shown during session restore ──────────────────────
class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bizType = ref.watch(businessTypeProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _bizColor(bizType),
              _bizColor(bizType).withAlpha(200),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppBrandLogo(height: 52, width: 220, showShadow: true),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.loading,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Color _bizColor(String type) {
    const map = <String, Color>{
      'pharmacy':    Color(0xFF1565C0),
      'hardware':    Color(0xFFBF360C),
      'restaurant':  Color(0xFFBF360C),
      'supermarket': Color(0xFF2E7D32),
    };
    return map[type] ?? const Color(0xFF1A3A6B);
  }
}

