import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/rbac/role_access.dart';
import '../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/permissions_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/drawer_menu_button.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _tabIndex(List<AppNavItem> tabs, BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(roleAccessProvider);
    final user = ref.watch(currentUserProvider);
    final bizType = ref.watch(businessTypeProvider);
    final primary = AppColors.forBusiness(bizType);
    final cartCount = ref.watch(cartItemCountProvider);
    final l10n = ref.watch(appLocalizationsProvider);

    if (access == null) return Scaffold(body: child);

    final bottomTabs = bottomNavFor(access);
    final drawerItems = drawerNavFor(access);
    final idx = bottomTabs.isEmpty ? 0 : _tabIndex(bottomTabs, context);

    return Scaffold(
      key: ref.read(shellScaffoldKeyProvider),
      drawer: _AppDrawer(
        user: user,
        access: access,
        drawerItems: drawerItems,
        primary: primary,
        l10n: l10n,
        onLogout: () => ref.read(authProvider.notifier).logout(),
      ),
      body: child,
      bottomNavigationBar: bottomTabs.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 60,
                  child: Row(
                    children: List.generate(bottomTabs.length, (i) {
                      final tab = bottomTabs[i];
                      final selected = i == idx;
                      final isPos = tab.path == '/pos';
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => context.go(tab.path),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    selected ? tab.activeIcon : tab.icon,
                                    color: selected
                                        ? primary
                                        : AppColors.textHint,
                                    size: 22,
                                  ),
                                  if (isPos && cartCount > 0)
                                    Positioned(
                                      right: -8,
                                      top: -6,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1.5),
                                        ),
                                        constraints: const BoxConstraints(
                                            minWidth: 16, minHeight: 16),
                                        child: Text(
                                          cartCount > 9 ? '9+' : '$cartCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  l10n.navLabel(tab.labelKey),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected
                                        ? primary
                                        : AppColors.textHint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final AuthUser? user;
  final RoleAccess access;
  final List<AppNavItem> drawerItems;
  final Color primary;
  final AppLocalizations l10n;
  final VoidCallback onLogout;

  const _AppDrawer({
    required this.user,
    required this.access,
    required this.drawerItems,
    required this.primary,
    required this.l10n,
    required this.onLogout,
  });

  String _roleLabel() {
    if (access.isOwner) return 'Owner';
    final role = user?.staffRole;
    if (role == null) return 'Staff';
    return staffRoleLabel(role);
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(
                    (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user?.businessName ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _roleLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ...drawerItems.map((item) {
                  final selected = loc.startsWith(item.path);
                  return ListTile(
                    leading: Icon(
                      selected ? item.activeIcon : item.icon,
                      color: selected ? primary : AppColors.textSecondary,
                    ),
                    title: Text(
                      l10n.navLabel(item.labelKey),
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? primary : AppColors.textPrimary,
                      ),
                    ),
                    selected: selected,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(item.path);
                    },
                  );
                }),
                if (access.canSeeSettings)
                  ListTile(
                    leading: Icon(
                      loc.startsWith('/settings')
                          ? Icons.settings_rounded
                          : Icons.settings_outlined,
                      color: loc.startsWith('/settings')
                          ? primary
                          : AppColors.textSecondary,
                    ),
                    title: Text(l10n.settings),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text(l10n.signOut, style: const TextStyle(color: AppColors.danger)),
            onTap: () {
              Navigator.pop(context);
              onLogout();
              context.go('/welcome');
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
