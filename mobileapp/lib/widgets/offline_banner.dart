import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/offline_messages.dart';
import '../l10n/app_localizations.dart';
import '../providers/connectivity_provider.dart';
import '../providers/locale_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    final pending = pendingAsync.maybeWhen(data: (c) => c, orElse: () => 0);

    if (isOnline && pending == 0) return const SizedBox.shrink();

    final message = isOnline
        ? (l10n.isSw
            ? 'Mabadiliko $pending yanasubiri kusawazishwa.'
            : '$pending change(s) waiting to sync.')
        : OfflineMessages.offlineBanner(l10n.isSw, pending);

    return Material(
      color: isOnline ? AppColors.primary.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.15),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.sync_rounded : Icons.wifi_off_rounded,
                size: 16,
                color: isOnline ? AppColors.primary : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOnline ? AppColors.primary : AppColors.warning,
                  ),
                ),
              ),
              if (!isOnline && pending > 0)
                Text(
                  '$pending',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
