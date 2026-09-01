import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/legal/terms_of_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_brand_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSw = ref.watch(localeProvider) == AppLanguage.sw;

    final body = ListView(
      padding: EdgeInsets.fromLTRB(20, embedded ? 8 : 16, 20, 32),
      children: [
        if (!embedded) ...[
          _HeroBanner(isSw: isSw),
          const SizedBox(height: 20),
        ],
        ...termsSections.map((s) => _SectionCard(section: s, isSw: isSw)),
        const SizedBox(height: 16),
        _ReminderBox(isSw: isSw),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/welcome');
                      }
                    },
                  ),
                  const Spacer(),
                  const AppBrandLogo(height: 32, width: 140),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.isSw});
  final bool isSw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2347), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  termsPageTitle(isSw),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isSw ? 'Makubaliano ya DukaMkononi' : 'DukaMkononi Service Agreement',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            termsHeroSubtitle(isSw),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 12),
          Text(
            '${isSw ? 'Imesasishwa' : 'Updated'}: $termsLastUpdated',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.isSw});
  final TermsSection section;
  final bool isSw;

  IconData get _icon {
    switch (section.id) {
      case 'tin':
        return Icons.business_rounded;
      case 'tra-efd':
        return Icons.receipt_long_rounded;
      case 'liability':
        return Icons.warning_amber_rounded;
      case 'service':
        return Icons.balance_rounded;
      default:
        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = section.highlight ? const Color(0xFFD97706) : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: section.highlight ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: section.highlight ? const Color(0xFFFDE68A) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title(isSw),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...section.body(isSw).map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderBox extends StatelessWidget {
  const _ReminderBox({required this.isSw});
  final bool isSw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 28),
          const SizedBox(height: 8),
          Text(
            isSw ? 'Kumbuka muhimu' : 'Important reminder',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            termsImportantReminder(isSw),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Required acceptance checkbox for registration flows.
class TermsAcceptanceTile extends StatelessWidget {
  const TermsAcceptanceTile({
    super.key,
    required this.isSw,
    required this.value,
    required this.onChanged,
    this.onOpenTerms,
  });

  final bool isSw;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onOpenTerms;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: value ? AppColors.primary : AppColors.border, width: value ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary),
                      children: [
                        TextSpan(text: isSw ? 'Nimesoma na nakubali ' : 'I have read and agree to the '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: onOpenTerms,
                            child: Text(
                              isSw ? 'Masharti ya Huduma' : 'Terms of Service',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: isSw
                              ? ', ikiwa ni pamoja na wajibu wangu wa TIN na TRA EFD. Ninaelewa Mtoa Huduma hatawajibika kwa taarifa za uongo.'
                              : ', including TIN and TRA EFD duties. I understand the provider is not liable for false information.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
