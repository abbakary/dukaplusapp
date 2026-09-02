import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Active branch workspace — null means owner/all-branches view.
final activeBranchIdProvider = StateProvider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  if (user.isTenantWide) return null;
  return user.branchId;
});

/// Human-readable branch label for scoped staff.
final activeBranchLabelProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  if (user.isTenantWide) return null;
  return user.branchName ?? user.branch;
});
