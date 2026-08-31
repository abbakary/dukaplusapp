import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
              style: const TextStyle(
                color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w700, letterSpacing: -0.5,
              ),
            ),
            if (subValue != null) ...[
              const SizedBox(height: 2),
              Text(subValue!,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            ],
            const SizedBox(height: 4),
            Text(label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact horizontal stat tile ─────────────────────────────────────────────
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                    style: TextStyle(
                      color: color, fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                  Text(label,
                    style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11,
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
