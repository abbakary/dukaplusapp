import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Text(title,
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
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
