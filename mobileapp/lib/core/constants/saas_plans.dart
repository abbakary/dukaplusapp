import '../utils/formatters.dart';
import 'app_constants.dart';

/// Public SaaS tiers — three paid plans, no free tier.
class SaasPlanInfo {
  const SaasPlanInfo({
    required this.tier,
    required this.nameEn,
    required this.nameSw,
    required this.tagEn,
    required this.tagSw,
    required this.priceMonthlyTzs,
    required this.maxBranches,
    required this.maxStaff,
    required this.featuresEn,
    required this.featuresSw,
    this.popular = false,
  });

  final String tier;
  final String nameEn;
  final String nameSw;
  final String tagEn;
  final String tagSw;
  final int priceMonthlyTzs;
  final int maxBranches;
  final int maxStaff;
  final List<String> featuresEn;
  final List<String> featuresSw;
  final bool popular;

  String name(bool isSw) => isSw ? nameSw : nameEn;
  String tag(bool isSw) => isSw ? tagSw : tagEn;
  List<String> features(bool isSw) => isSw ? featuresSw : featuresEn;
  String priceLabel() => AppFormatters.tsh(priceMonthlyTzs);
}

class SaasPlans {
  SaasPlans._();

  static const List<SaasPlanInfo> publicPlans = [
    SaasPlanInfo(
      tier: AppConstants.planStarter,
      nameEn: 'Plan 1 — Starter',
      nameSw: 'Mpango 1 — Starter',
      tagEn: 'Single branch — one shop',
      tagSw: 'Tawi moja — duka moja',
      priceMonthlyTzs: 49000,
      maxBranches: 1,
      maxStaff: 3,
      featuresEn: ['POS & barcode', 'Inventory alerts', 'Customer CRM', 'Basic reports'],
      featuresSw: ['POS na barcode', 'Arifa za stoo', 'CRM ya wateja', 'Ripoti za msingi'],
    ),
    SaasPlanInfo(
      tier: AppConstants.planPro,
      nameEn: 'Plan 2 — Biashara Pro',
      nameSw: 'Mpango 2 — Biashara Pro',
      tagEn: 'Growing business — 2 branches',
      tagSw: 'Biashara inayokua — matawi 2',
      priceMonthlyTzs: 99000,
      maxBranches: 2,
      maxStaff: 10,
      featuresEn: ['TRA EFD receipts', 'RBAC staff', 'AI insights', '2 branches'],
      featuresSw: ['Risiti TRA EFD', 'Mamlaka RBAC', 'Ushauri wa AI', 'Matawi 2'],
      popular: true,
    ),
    SaasPlanInfo(
      tier: AppConstants.planEnterprise,
      nameEn: 'Plan 3 — Enterprise',
      nameSw: 'Mpango 3 — Biashara Kubwa',
      tagEn: 'Store chains — 3 branches',
      tagSw: 'Minyororo ya maduka — matawi 3',
      priceMonthlyTzs: 249000,
      maxBranches: 3,
      maxStaff: 15,
      featuresEn: ['3 branches', 'API access', 'Dedicated support', 'Consolidated reports'],
      featuresSw: ['Matawi 3', 'API', 'Msaada maalum', 'Ripoti za pamoja'],
    ),
  ];

  static SaasPlanInfo? byTier(String tier) {
    for (final p in publicPlans) {
      if (p.tier == tier) return p;
    }
    return null;
  }

  static String branchLabel(int maxBranches, bool isSw) {
    if (isSw) return maxBranches == 1 ? 'Tawi 1' : 'Matawi $maxBranches';
    return maxBranches == 1 ? '1 branch' : '$maxBranches branches';
  }
}
