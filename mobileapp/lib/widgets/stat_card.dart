import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StatCard — animated premium gradient KPI card
// ─────────────────────────────────────────────────────────────────────────────
class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? trend; // e.g. "+12%" or "-5%"
  final bool trendPositive;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.trailing,
    this.trend,
    this.trendPositive = true,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:   widget.gradient.colors.first.withValues(alpha: 0.30),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + optional trailing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                if (widget.trailing != null)
                  widget.trailing!
                else if (widget.onTap != null)
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Value
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(widget.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.0,
                )),
            ),
            if (widget.subValue != null) ...[
              const SizedBox(height: 3),
              Text(widget.subValue!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 11,
                )),
            ],
            const SizedBox(height: 6),
            // Label + trend badge
            Row(
              children: [
                Expanded(
                  child: Text(widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:      Colors.white.withValues(alpha: 0.85),
                      fontSize:   11,
                      fontWeight: FontWeight.w500,
                    )),
                ),
                if (widget.trend != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(widget.trend!,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   10,
                        fontWeight: FontWeight.w700,
                      )),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap!(); },
      onTapCancel: () => _ctrl.reverse(),
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// InfoCard — lighter flat card with icon and single value
// ─────────────────────────────────────────────────────────────────────────────
class InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
              style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.w800,
                color:      color,
                letterSpacing: -0.3,
              )),
            const SizedBox(height: 2),
            Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500,
              )),
          ],
        ),
      ),
    );
  }
}
