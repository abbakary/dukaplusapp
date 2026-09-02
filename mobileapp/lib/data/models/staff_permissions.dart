import 'package:flutter/foundation.dart';
import 'user_model.dart';

@immutable
class StaffPermissions {
  final bool canSellPOS;
  final bool canGiveCredit;
  final bool canModifyInventory;
  final bool canViewProfitReports;
  final bool canManageSuppliers;
  final bool canApproveDiscounts;
  final bool canOverridePrices;
  final bool canVoidReceipts;
  final bool canPerformDailyClosing;
  final bool canAccessSuperAdmin;

  const StaffPermissions({
    this.canSellPOS = false,
    this.canGiveCredit = false,
    this.canModifyInventory = false,
    this.canViewProfitReports = false,
    this.canManageSuppliers = false,
    this.canApproveDiscounts = false,
    this.canOverridePrices = false,
    this.canVoidReceipts = false,
    this.canPerformDailyClosing = false,
    this.canAccessSuperAdmin = false,
  });

  factory StaffPermissions.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const StaffPermissions();
    return StaffPermissions(
      canSellPOS: j['canSellPOS'] == true || j['can_sell_pos'] == true,
      canGiveCredit: j['canGiveCredit'] == true || j['can_give_credit'] == true,
      canModifyInventory: j['canModifyInventory'] == true || j['can_modify_inventory'] == true,
      canViewProfitReports: j['canViewProfitReports'] == true || j['can_view_profit_reports'] == true,
      canManageSuppliers: j['canManageSuppliers'] == true || j['can_manage_suppliers'] == true,
      canApproveDiscounts: j['canApproveDiscounts'] == true || j['can_approve_discounts'] == true,
      canOverridePrices: j['canOverridePrices'] == true || j['can_override_prices'] == true,
      canVoidReceipts: j['canVoidReceipts'] == true || j['can_void_receipts'] == true,
      canPerformDailyClosing: j['canPerformDailyClosing'] == true || j['can_perform_daily_closing'] == true,
      canAccessSuperAdmin: j['canAccessSuperAdmin'] == true || j['can_access_super_admin'] == true,
    );
  }

}

StaffPermissions defaultPermissionsForRole(StaffRole role) {
  switch (role) {
    case StaffRole.owner:
    case StaffRole.manager:
      return const StaffPermissions(
        canSellPOS: true,
        canGiveCredit: true,
        canModifyInventory: true,
        canViewProfitReports: true,
        canManageSuppliers: true,
        canApproveDiscounts: true,
        canOverridePrices: true,
        canVoidReceipts: true,
        canPerformDailyClosing: true,
      );
    case StaffRole.pharmacist:
      return const StaffPermissions(
        canSellPOS: true,
        canGiveCredit: true,
        canModifyInventory: true,
        canManageSuppliers: true,
        canApproveDiscounts: true,
        canOverridePrices: true,
        canVoidReceipts: true,
      );
    case StaffRole.cashier:
      return const StaffPermissions(
        canSellPOS: true,
        canPerformDailyClosing: true,
      );
    case StaffRole.storekeeper:
      return const StaffPermissions(
        canModifyInventory: true,
        canManageSuppliers: true,
      );
    case StaffRole.accountant:
      return const StaffPermissions(
        canGiveCredit: true,
        canModifyInventory: true,
        canViewProfitReports: true,
        canManageSuppliers: true,
        canPerformDailyClosing: true,
      );
  }
}

StaffPermissions resolvePermissions(AuthUser user) {
  if (user.role == UserRole.vendorOwner) {
    return defaultPermissionsForRole(StaffRole.owner);
  }
  if (user.role == UserRole.superAdmin) {
    return const StaffPermissions(
      canAccessSuperAdmin: true,
      canSellPOS: true,
      canViewProfitReports: true,
      canModifyInventory: true,
      canManageSuppliers: true,
      canOverridePrices: true,
      canApproveDiscounts: true,
    );
  }
  final role = user.staffRole ?? StaffRole.cashier;
  final defaults = defaultPermissionsForRole(role);
  final api = user.permissions;
  if (api == null || _permissionsEmpty(api)) return defaults;
  return api;
}

bool _permissionsEmpty(StaffPermissions p) =>
    !p.canSellPOS &&
    !p.canGiveCredit &&
    !p.canModifyInventory &&
    !p.canViewProfitReports &&
    !p.canManageSuppliers &&
    !p.canApproveDiscounts &&
    !p.canOverridePrices &&
    !p.canVoidReceipts &&
    !p.canPerformDailyClosing &&
    !p.canAccessSuperAdmin;
