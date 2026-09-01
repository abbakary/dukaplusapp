import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../providers/ai_provider.dart';
import '../providers/locale_provider.dart';

/// App-bar AI entry point — avoids overlapping screen FABs and bottom actions.
class AiAppBarButton extends ConsumerWidget {
  final String? prompt;

  const AiAppBarButton({super.key, this.prompt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    return IconButton(
      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      tooltip: l10n.aiPro,
      onPressed: () => ref.read(aiChatProvider.notifier).open(prompt: prompt),
    );
  }
}

/// Compact amber chip used on dashboard for contextual AI prompts.
class AiPromptChip extends ConsumerWidget {
  final String label;
  final String? prompt;
  final IconData icon;
  final bool expanded;

  const AiPromptChip({
    super.key,
    required this.label,
    this.prompt,
    this.icon = Icons.auto_awesome_rounded,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onTap = () => ref.read(aiChatProvider.notifier).open(prompt: prompt);

    if (expanded) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF6264A7)),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: const Color(0xFFF3F2F1),
      side: const BorderSide(color: AppColors.border),
      onPressed: onTap,
    );
  }
}
