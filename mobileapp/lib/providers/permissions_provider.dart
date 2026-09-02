import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/rbac/role_access.dart';
import '../core/rbac/pos_pricing_access.dart';
import '../data/models/staff_permissions.dart';
import 'auth_provider.dart';
import 'business_settings_provider.dart';

final roleAccessProvider = Provider<RoleAccess?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return RoleAccess(user);
});

final staffPermissionsProvider = Provider<StaffPermissions>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const StaffPermissions();
  return resolvePermissions(user);
});

final posPricingAccessProvider = Provider<PosPricingAccess>((ref) {
  final user = ref.watch(currentUserProvider);
  final settings = ref.watch(businessSettingsProvider);
  return resolvePosPricingAccess(user, settings);
});
