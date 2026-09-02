import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/rbac/role_access.dart';
import '../core/theme/app_colors.dart';
import '../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/permissions_provider.dart';
import '../providers/products_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/sales_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/shell_scope.dart';
import '../providers/ai_provider.dart';
import '../widgets/offline_banner.dart';
import '../widgets/ai_chat_sheet.dart';
import '../providers/connectivity_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main Shell
// ─────────────────────────────────────────────────────────────────────────────
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool? _wasOnline;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final access    = ref.watch(roleAccessProvider);
    final user      = ref.watch(currentUserProvider);
    final bizType   = ref.watch(businessTypeProvider);
    final primary   = AppColors.forBusiness(bizType);
    final cartCount = ref.watch(cartItemCountProvider);
    final l10n      = ref.watch(appLocalizationsProvider);
    final isOnline  = ref.watch(isOnlineProvider);

    if (_wasOnline == false && isOnline) {
      Future.microtask(() async {
        final sync = ref.read(offlineSyncServiceProvider);
        await sync.syncAll();
        ref.read(syncRefreshProvider.notifier).state++;
        ref.read(productsRefreshProvider.notifier).state++;
        ref.read(customersRefreshProvider.notifier).state++;
        ref.read(salesRefreshProvider.notifier).state++;
      });
    }
    _wasOnline = isOnline;

    if (access == null) return Scaffold(body: widget.child);

    final bottomTabs  = bottomNavFor(access);
    final drawerItems = drawerNavFor(access);
    final idx         = bottomTabs.isEmpty ? 0 : _tabIndex(bottomTabs, context);

    return ShellScope(
      scaffoldKey: _scaffoldKey,
      child: Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: _AppDrawer(
            user:        user,
            access:      access,
            drawerItems: drawerItems,
            primary:     primary,
            l10n:        l10n,
            onLogout:    () => ref.read(authProvider.notifier).logout(),
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: widget.child),
            ],
          ),
          bottomNavigationBar: bottomTabs.isEmpty
              ? null
              : _BottomNav(
                  tabs:      bottomTabs,
                  idx:       idx,
                  primary:   primary,
                  cartCount: cartCount,
                  l10n:      l10n,
                ),
        ),
        if (ref.watch(aiChatProvider).isOpen) const AiChatSheet(),
      ],
    ),
    );
  }

  int _tabIndex(List<AppNavItem> tabs, BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation Bar — WhatsApp / Yas style
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final List<AppNavItem> tabs;
  final int idx;
  final Color primary;
  final int cartCount;
  final AppLocalizations l10n;

  const _BottomNav({
    required this.tabs,
    required this.idx,
    required this.primary,
    required this.cartCount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFDDE3EC), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,   // taller than 60 — fits icons + labels on real devices
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab      = tabs[i];
              final selected = i == idx;
              final isPos    = tab.path == '/pos';
              return Expanded(child: _NavItem(
                tab:       tab,
                selected:  selected,
                isPos:     isPos,
                cartCount: cartCount,
                primary:   primary,
                l10n:      l10n,
                onTap:     () => context.go(tab.path),
              ));
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final AppNavItem tab;
  final bool selected;
  final bool isPos;
  final int cartCount;
  final Color primary;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.isPos,
    required this.cartCount,
    required this.primary,
    required this.l10n,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color    = selected ? widget.primary : AppColors.textHint;

    return GestureDetector(
      onTap:     _handleTap,
      behavior:  HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder:   (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:      MainAxisSize.min,
          children: [
            // Icon container with animated pill background
            AnimatedContainer(
              duration:    const Duration(milliseconds: 200),
              curve:       Curves.easeOutCubic,
              width:       selected ? 52 : 40,
              height:      32,
              decoration:  BoxDecoration(
                color:         selected ? widget.primary.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius:  BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration:        const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      selected ? widget.tab.activeIcon : widget.tab.icon,
                      key:   ValueKey(selected),
                      color: color,
                      size:  24,   // larger icon for real devices
                    ),
                  ),
                  // Cart badge
                  if (widget.isPos && widget.cartCount > 0)
                    Positioned(
                      right: -4,
                      top:   -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          widget.cartCount > 9 ? '9+' : '${widget.cartCount}',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize:   11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color:      color,
                letterSpacing: selected ? 0.1 : 0,
              ),
              child: Text(
                widget.l10n.navLabel(widget.tab.labelKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawer
// ─────────────────────────────────────────────────────────────────────────────
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
    final loc       = GoRouterState.of(context).matchedLocation;
    final topPad    = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final initial   = (user?.name ?? 'U').substring(0, 1).toUpperCase();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withValues(alpha: 0.97), primary.withValues(alpha: 0.82)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.40), width: 2),
                  ),
                  child: Center(
                    child: Text(initial,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(user?.businessName ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82), fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                      ),
                      child: Text(_roleLabel(),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    if (user?.email != null)
                      Expanded(
                        child: Text(user!.email!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68), fontSize: 11)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // ── Nav items ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ...drawerItems.map((item) {
                  final selected = loc.startsWith(item.path);
                  return _DrawerItem(
                    icon:         selected ? item.activeIcon : item.icon,
                    label:        l10n.navLabel(item.labelKey),
                    selected:     selected,
                    selectedColor: primary,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(item.path);
                    },
                  );
                }),
                if (access.canSeeSettings)
                  _DrawerItem(
                    icon:         loc.startsWith('/settings')
                        ? Icons.settings_rounded
                        : Icons.settings_outlined,
                    label:        l10n.settings,
                    selected:     loc.startsWith('/settings'),
                    selectedColor: primary,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                  ),
              ],
            ),
          ),
          // ── Footer ───────────────────────────────────────────────
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
            ),
            title: Text(l10n.signOut,
              style: const TextStyle(
                color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              onLogout();
              context.go('/welcome');
            },
          ),
          SizedBox(height: bottomPad + 4),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? selectedColor.withValues(alpha: 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? selectedColor.withValues(alpha: 0.14)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Text(label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? selectedColor : AppColors.textPrimary,
                    fontSize: 14,
                  )),
                if (selected) ...[
                  const Spacer(),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: selectedColor, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
