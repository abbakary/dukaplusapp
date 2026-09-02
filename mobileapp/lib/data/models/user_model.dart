import 'package:flutter/foundation.dart';
import 'staff_permissions.dart';

enum UserRole { vendorOwner, vendorStaff, superAdmin }
enum StaffRole { owner, manager, pharmacist, cashier, storekeeper, accountant }

UserRole userRoleFromString(String? s) {
  switch (s) {
    case 'super_admin':   return UserRole.superAdmin;
    case 'vendor_staff':  return UserRole.vendorStaff;
    default:              return UserRole.vendorOwner;
  }
}

StaffRole staffRoleFromString(String? s) {
  switch (s?.toLowerCase()) {
    case 'manager':      return StaffRole.manager;
    case 'pharmacist':   return StaffRole.pharmacist;
    case 'cashier':      return StaffRole.cashier;
    case 'storekeeper':  return StaffRole.storekeeper;
    case 'accountant':   return StaffRole.accountant;
    default:             return StaffRole.owner;
  }
}

String staffRoleLabel(StaffRole role) {
  switch (role) {
    case StaffRole.owner:
      return 'Owner';
    case StaffRole.manager:
      return 'Manager';
    case StaffRole.pharmacist:
      return 'Pharmacist';
    case StaffRole.cashier:
      return 'Cashier';
    case StaffRole.storekeeper:
      return 'Storekeeper';
    case StaffRole.accountant:
      return 'Accountant';
  }
}

String userRoleKey(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
      return 'super_admin';
    case UserRole.vendorStaff:
      return 'vendor_staff';
    case UserRole.vendorOwner:
      return 'vendor_owner';
  }
}

@immutable
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final StaffRole? staffRole;
  final String? businessId;
  final String? businessName;
  final String? businessType;
  final String? branch;
  final String? branchId;
  final String? branchName;
  final bool isBranchScoped;
  final String? plan;
  final String? tinNumber;
  final String? staffId;
  final String? avatarColor;
  final StaffPermissions? permissions;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.staffRole,
    this.businessId,
    this.businessName,
    this.businessType,
    this.branch,
    this.branchId,
    this.branchName,
    this.isBranchScoped = false,
    this.plan,
    this.tinNumber,
    this.staffId,
    this.avatarColor,
    this.permissions,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id:           j['id']?.toString() ?? '',
    name:         j['name']?.toString() ?? j['owner_name']?.toString() ?? '',
    email:        j['email']?.toString() ?? '',
    phone:        j['phone']?.toString(),
    role:         userRoleFromString(j['role']?.toString()),
    staffRole:    j['staff_role'] != null ? staffRoleFromString(j['staff_role'].toString()) : null,
    businessId:   j['business_id']?.toString() ?? j['id']?.toString(),
    businessName: j['business_name']?.toString(),
    businessType: j['business_type']?.toString(),
    branch:       j['branch']?.toString() ?? j['branch_name']?.toString(),
    branchId:     j['branch_id']?.toString(),
    branchName:   j['branch_name']?.toString(),
    isBranchScoped: j['is_branch_scoped'] == true,
    plan:         j['plan']?.toString(),
    tinNumber:    j['tin_number']?.toString(),
    staffId:      j['staff_id']?.toString(),
    avatarColor:  j['avatar_color']?.toString(),
    permissions:  j['permissions'] != null
        ? StaffPermissions.fromJson(j['permissions'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'phone': phone,
    'role': userRoleKey(role), 'business_id': businessId,
    'business_name': businessName, 'business_type': businessType,
    'branch': branch, 'plan': plan, 'tin_number': tinNumber,
  };

  bool get isOwner      => role == UserRole.vendorOwner;
  bool get isStaff      => role == UserRole.vendorStaff;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isTenantWide => isOwner || staffRole == StaffRole.owner;
  bool get isCashier    => staffRole == StaffRole.cashier;
  bool get isManager    => staffRole == StaffRole.manager || role == UserRole.vendorOwner;

  AuthUser copyWith({
    String? name, String? businessType, String? businessName,
    StaffRole? staffRole, String? branch,
  }) => AuthUser(
    id: id, email: email, phone: phone, role: role,
    businessId: businessId, plan: plan, tinNumber: tinNumber,
    staffId: staffId, avatarColor: avatarColor,
    name: name ?? this.name,
    businessType: businessType ?? this.businessType,
    businessName: businessName ?? this.businessName,
    staffRole: staffRole ?? this.staffRole,
    branch: branch ?? this.branch,
  );
}
