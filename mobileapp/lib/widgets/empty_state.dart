import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// General empty / zero-data state.
///
/// Adapts automatically to the available space:
/// - In tight constraints (e.g. inside a short [Expanded]) it collapses to a
///   single centred row (icon + text) so it never overflows.
/// - In generous constraints it shows the full centred column layout.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tight areas (e.g. POS grid slot beside banners) — compact layout only.
        if (constraints.maxHeight < 220) {
          final showAction =
              actionLabel != null && onAction != null && constraints.maxHeight >= 96;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20, color: primary.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  if (showAction) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(actionLabel!, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Normal full layout.
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: primary.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String title;
  final String? retryLabel;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    required this.title,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: title,
        subtitle: message,
        actionLabel: onRetry != null ? retryLabel : null,
        onAction: onRetry,
      );
}
