import 'package:flutter/material.dart';
import '../../data/models/staff_permissions.dart';
import '../../data/models/user_model.dart';

/// Mirrors React `Sidebar.tsx` visibility rules.
class RoleAccess {
  RoleAccess(this.user);

  final AuthUser user;
  late final StaffPermissions p = resolvePermissions(user);

  bool get isOwner => user.role == UserRole.vendorOwner || user.staffRole == StaffRole.owner;
  bool get isManager => isOwner || user.staffRole == StaffRole.manager;
  bool get isPharmacist => user.staffRole == StaffRole.pharmacist;
  bool get isCashier => user.staffRole == StaffRole.cashier;
  bool get isStorekeeper => user.staffRole == StaffRole.storekeeper;
  bool get isAccountant => user.staffRole == StaffRole.accountant;

  bool get canSeeDashboard => isOwner || isManager || isAccountant;
  bool get canSeePOS => isOwner || isManager || isCashier || isPharmacist || p.canSellPOS;
  bool get canSeeCustomers => isOwner || isManager || isCashier || isAccountant || isPharmacist;
  bool get canSeeInventory => isOwner || isManager || isStorekeeper || isPharmacist || p.canModifyInventory;
  bool get canSeeSuppliers => isOwner || isManager || isStorekeeper || isAccountant || p.canManageSuppliers;
  bool get canSeeReports => isOwner || isManager || isAccountant || p.canViewProfitReports;
  bool get canSeeDocuments => isOwner || isManager || isAccountant;
  bool get canSeeBI => isOwner || isManager || isAccountant;
  bool get canSeeBranches => isOwner || isManager;
  bool get canSeeExpenses => isOwner || isManager || isAccountant;
  bool get canManageExpenses => isOwner || isManager || isAccountant || p.canViewProfitReports;
  bool get canManagePayroll => isOwner || isManager;
  bool get canConfigureAllowances => canManagePayroll;
  bool get canApproveAdvances => canManagePayroll;
  bool get canClaimOwnStipend => p.canPerformDailyClosing || p.canSellPOS;
  bool get canSeeReceivables => isOwner || isManager || isCashier || isAccountant || p.canGiveCredit;
  bool get canSettleCustomerDebt => canSeeReceivables || p.canSellPOS;
  bool get canSettleSupplierPayable => isOwner || isManager || isAccountant || isStorekeeper || p.canManageSuppliers;
  bool get canSeePending => canSeePOS;
  bool get canSeeSettings => true;
  bool get canManageAccount => isOwner;

  bool canAccessPath(String path) {
    if (path.startsWith('/settings')) return canSeeSettings;
    if (path.startsWith('/dashboard')) return canSeeDashboard;
    if (path.startsWith('/pos')) return canSeePOS;
    if (path.startsWith('/inventory')) return canSeeInventory;
    if (path.startsWith('/customers')) return canSeeCustomers;
    if (path.startsWith('/suppliers')) return canSeeSuppliers;
    if (path.startsWith('/reports')) return canSeeReports;
    if (path.startsWith('/documents')) return canSeeDocuments;
    if (path.startsWith('/bi')) return canSeeBI;
    if (path.startsWith('/branches')) return canSeeBranches;
    if (path.startsWith('/expenses')) return canSeeExpenses;
    if (path.startsWith('/my-stipend')) return canClaimOwnStipend;
    if (path.startsWith('/credit')) return canSeeReceivables;
    if (path.startsWith('/pending')) return canSeePending;
    return true;
  }

  String? defaultLandingPath() {
    if (canSeeDashboard) return '/dashboard';
    if (canSeePOS) return '/pos';
    if (canSeeInventory) return '/inventory';
    if (canSeeCustomers) return '/customers';
    if (canSeeReports) return '/reports';
    return '/settings';
  }
}

class AppNavItem {
  final String path;
  final String labelKey;
  final IconData activeIcon;
  final IconData icon;
  final bool Function(RoleAccess access) visible;
  final bool showInBottomNav;

  const AppNavItem({
    required this.path,
    required this.labelKey,
    required this.activeIcon,
    required this.icon,
    required this.visible,
    this.showInBottomNav = false,
  });
}

List<AppNavItem> allNavItems = [
  AppNavItem(
    path: '/dashboard',
    labelKey: 'home',
    activeIcon: Icons.dashboard_rounded,
    icon: Icons.dashboard_outlined,
    visible: (a) => a.canSeeDashboard,
    showInBottomNav: true,
  ),
  AppNavItem(
    path: '/pos',
    labelKey: 'pos',
    activeIcon: Icons.point_of_sale_rounded,
    icon: Icons.point_of_sale_outlined,
    visible: (a) => a.canSeePOS,
    showInBottomNav: true,
  ),
  AppNavItem(
    path: '/inventory',
    labelKey: 'stock',
    activeIcon: Icons.inventory_2_rounded,
    icon: Icons.inventory_2_outlined,
    visible: (a) => a.canSeeInventory,
    showInBottomNav: true,
  ),
  AppNavItem(
    path: '/customers',
    labelKey: 'clients',
    activeIcon: Icons.people_rounded,
    icon: Icons.people_outline_rounded,
    visible: (a) => a.canSeeCustomers,
    showInBottomNav: true,
  ),
  AppNavItem(
    path: '/reports',
    labelKey: 'reports',
    activeIcon: Icons.bar_chart_rounded,
    icon: Icons.bar_chart_outlined,
    visible: (a) => a.canSeeReports,
    showInBottomNav: true,
  ),
  AppNavItem(
    path: '/documents',
    labelKey: 'documents',
    activeIcon: Icons.description_rounded,
    icon: Icons.description_outlined,
    visible: (a) => a.canSeeDocuments,
  ),
  AppNavItem(
    path: '/bi',
    labelKey: 'bi',
    activeIcon: Icons.insights_rounded,
    icon: Icons.insights_outlined,
    visible: (a) => a.canSeeBI,
  ),
  AppNavItem(
    path: '/pending',
    labelKey: 'pending',
    activeIcon: Icons.pending_actions_rounded,
    icon: Icons.pending_actions_outlined,
    visible: (a) => a.canSeePending,
  ),
  AppNavItem(
    path: '/suppliers',
    labelKey: 'suppliers',
    activeIcon: Icons.local_shipping_rounded,
    icon: Icons.local_shipping_outlined,
    visible: (a) => a.canSeeSuppliers,
  ),
  AppNavItem(
    path: '/credit',
    labelKey: 'credit',
    activeIcon: Icons.account_balance_wallet_rounded,
    icon: Icons.account_balance_wallet_outlined,
    visible: (a) => a.canSeeReceivables,
  ),
  AppNavItem(
    path: '/expenses',
    labelKey: 'expenses',
    activeIcon: Icons.receipt_long_rounded,
    icon: Icons.receipt_long_outlined,
    visible: (a) => a.canSeeExpenses,
  ),
  AppNavItem(
    path: '/branches',
    labelKey: 'branches',
    activeIcon: Icons.store_mall_directory_rounded,
    icon: Icons.store_mall_directory_outlined,
    visible: (a) => a.canSeeBranches,
  ),
  AppNavItem(
    path: '/my-stipend',
    labelKey: 'myStipend',
    activeIcon: Icons.lunch_dining_rounded,
    icon: Icons.lunch_dining_outlined,
    visible: (a) => a.canClaimOwnStipend,
  ),
  AppNavItem(
    path: '/settings',
    labelKey: 'settings',
    activeIcon: Icons.settings_rounded,
    icon: Icons.settings_outlined,
    visible: (a) => a.canSeeSettings,
  ),
];

List<AppNavItem> bottomNavFor(RoleAccess access) =>
    allNavItems.where((n) => n.showInBottomNav && n.visible(access)).take(5).toList();

List<AppNavItem> drawerNavFor(RoleAccess access) =>
    allNavItems.where((n) => !n.showInBottomNav && n.visible(access)).toList();
