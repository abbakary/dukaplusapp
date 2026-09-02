import '../config/business_settings.dart';
import '../../data/models/staff_permissions.dart';
import '../../data/models/user_model.dart';

class PosPricingAccess {
  final bool canApplyDiscount;
  final bool canApproveHighDiscount;
  final double maxDiscountPercent;
  final bool canOverridePrice;
  final bool canUsePartialPayment;
  final bool canNegotiate;

  const PosPricingAccess({
    this.canApplyDiscount = false,
    this.canApproveHighDiscount = false,
    this.maxDiscountPercent = 15,
    this.canOverridePrice = false,
    this.canUsePartialPayment = false,
    this.canNegotiate = false,
  });
}

PosPricingAccess resolvePosPricingAccess(
  AuthUser? user,
  BusinessSettings settings,
) {
  final perms = user != null ? resolvePermissions(user) : const StaffPermissions();
  return PosPricingAccess(
    canApplyDiscount: settings.discountEnabled && perms.canSellPOS,
    canApproveHighDiscount: perms.canApproveDiscounts,
    maxDiscountPercent: settings.maxDiscountPercent,
    canOverridePrice: settings.priceOverrideEnabled &&
        (perms.canOverridePrices || perms.canApproveDiscounts),
    canUsePartialPayment: settings.partialPaymentEnabled && perms.canGiveCredit,
    canNegotiate: settings.negotiationEnabled &&
        settings.partialPaymentEnabled &&
        perms.canGiveCredit,
  );
}
