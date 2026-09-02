import 'package:flutter/material.dart';
import '../core/constants/saas_plans.dart';
import '../core/theme/app_colors.dart';

/// Compact plan card for welcome carousel or register selection.
class PlanPricingCard extends StatelessWidget {
  const PlanPricingCard({
    super.key,
    required this.plan,
    required this.isSw,
    this.selected = false,
    this.compact = false,
    this.onTap,
  });

  final SaasPlanInfo plan;
  final bool isSw;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  static const _teal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? _teal : AppColors.border;
    final bg = selected ? _teal.withValues(alpha: 0.06) : Colors.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        child: Container(
          width: compact ? 168 : null,
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (plan.popular)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSw ? 'Maarufu' : 'Popular',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _teal),
                  ),
                ),
              Text(
                plan.name(isSw),
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  SaasPlans.branchLabel(plan.maxBranches, isSw),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _teal),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.priceLabel(),
                style: TextStyle(
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                isSw ? '/mwezi' : '/mo',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              if (!compact) ...[
                const SizedBox(height: 6),
                Text(
                  plan.tag(isSw),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
              if (selected) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: _teal),
                    const SizedBox(width: 4),
                    Text(
                      isSw ? 'Imechaguliwa' : 'Selected',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _teal),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
