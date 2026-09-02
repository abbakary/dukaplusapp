import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/report_pdf_builder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/offline_sync_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/business_settings_provider.dart';
import '../../data/models/dashboard_model.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/gradient_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth    = ref.watch(authProvider);
    final user    = auth.user;
    final bizType = auth.businessType;
    final primary = Theme.of(context).colorScheme.primary;
    final l10n    = ref.watch(appLocalizationsProvider);
    final lang    = ref.watch(localeProvider);
    final access  = ref.watch(roleAccessProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.settings, subtitle: l10n.settingsSubtitle),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile card ────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientForBusiness(bizType),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Owner',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(user?.email ?? '',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(user?.businessName ?? 'My Store',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.profileEditWeb),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Business Type section ───────────────────────────
            _SectionHeader(l10n.businessConfiguration),
            _SettingsTile(
              icon: Icons.store_outlined,
              title: l10n.businessType,
              subtitle: l10n.businessTypeLabel(AppConstants.businessTypes.firstWhere(
                (t) => t['id'] == bizType, orElse: () => AppConstants.businessTypes[2])),
              onTap: () => _showBusinessTypeSelector(context, ref, l10n),
            ),
            _SettingsTile(
              icon: Icons.receipt_long_outlined,
              title: l10n.tinNumber,
              subtitle: user?.tinNumber ?? l10n.notSet,
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.calculate_outlined,
              title: l10n.vatSettings,
              subtitle: l10n.vatStandard,
              onTap: () => context.push('/documents'),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: l10n.documentTemplates,
              subtitle: l10n.documentTemplatesSubtitle,
              onTap: () => context.push('/documents'),
            ),
            _SettingsTile(
              icon: Icons.discount_outlined,
              title: l10n.discountSettings,
              subtitle: ref.watch(businessSettingsProvider).discountEnabled
                  ? l10n.discountEnabled
                  : l10n.discountDisabled,
              onTap: () => context.push('/documents'),
            ),

            _SectionHeader(l10n.application),
            _SettingsTile(
              icon: Icons.language_outlined,
              title: l10n.language,
              subtitle: lang == AppLanguage.sw ? l10n.languageSw : l10n.languageEn,
              onTap: () => _showLanguagePicker(context, ref, l10n),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: l10n.notifications,
              subtitle: l10n.notificationsSubtitle,
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: l10n.pinSecurity,
              subtitle: l10n.pinSecuritySubtitle,
              onTap: () {},
            ),
            if (access?.canClaimOwnStipend == true)
              _SettingsTile(
                icon: Icons.lunch_dining_outlined,
                title: l10n.dailyStipends,
                subtitle: l10n.confirmAllowance,
                onTap: () => context.push('/my-stipend'),
              ),

            _SectionHeader(l10n.dataSync),
            _SettingsTile(
              icon: Icons.sync_rounded,
              title: l10n.syncData,
              subtitle: l10n.syncDataSubtitle,
              onTap: () async {
                final sync = ref.read(offlineSyncServiceProvider);
                final result = await sync.syncAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Synced ${result.processed} item(s)'
                        '${result.failed > 0 ? ', ${result.failed} failed' : ''}',
                      ),
                    ),
                  );
                  ref.invalidate(offlinePendingCountProvider);
                }
              },
            ),
            _SettingsTile(
              icon: Icons.cloud_download_outlined,
              title: l10n.exportData,
              subtitle: l10n.exportSubtitle,
              onTap: () async {
                final stats = ref.read(refreshedDashboardProvider).valueOrNull
                    ?? DashboardStats.demo();
                try {
                  await exportSalesReportPdf(
                    user:  ref.read(currentUserProvider),
                    stats: stats,
                    isSw:  ref.read(localeProvider) == AppLanguage.sw,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.errorMessage(e.toString())),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
            ),

            _SectionHeader(l10n.about),
            _SettingsTile(
              icon: Icons.gavel_outlined,
              title: ref.watch(localeProvider) == AppLanguage.sw ? 'Masharti ya Huduma' : 'Terms of Service',
              subtitle: ref.watch(localeProvider) == AppLanguage.sw ? 'TRA EFD, TIN & wajibu wa mteja' : 'TRA EFD, TIN & client duties',
              onTap: () => context.push('/terms'),
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: l10n.appVersion,
              subtitle: 'Duka+ v1.0.0',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: l10n.helpSupport,
              subtitle: l10n.helpSubtitle,
              onTap: () {},
            ),

            // ── Logout ──────────────────────────────────────────
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  label: Text(l10n.signOut, style: const TextStyle(color: AppColors.danger, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showBusinessTypeSelector(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusinessTypeSheet(ref: ref, l10n: l10n),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.chooseLanguage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ListTile(
                title: Text(l10n.languageSw),
                trailing: ref.watch(localeProvider) == AppLanguage.sw ? const Icon(Icons.check, color: Color(0xFF0d9488)) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLanguage(AppLanguage.sw);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(l10n.languageEn),
                trailing: ref.watch(localeProvider) == AppLanguage.en ? const Icon(Icons.check, color: Color(0xFF0d9488)) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLanguage(AppLanguage.en);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final l10n = ref.read(appLocalizationsProvider);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/welcome');
            },
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
    child: Text(title.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: AppColors.textHint, letterSpacing: 0.8)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primary, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class _BusinessTypeSheet extends StatefulWidget {
  final WidgetRef ref;
  final AppLocalizations l10n;
  const _BusinessTypeSheet({required this.ref, required this.l10n});

  @override
  State<_BusinessTypeSheet> createState() => _BusinessTypeSheetState();
}

class _BusinessTypeSheetState extends State<_BusinessTypeSheet> {
  String _selected = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.ref.read(businessTypeProvider);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(widget.l10n.businessType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      widget.ref.read(authProvider.notifier).updateBusinessType(_selected);
                      Navigator.pop(context);
                    },
                    child: Text(widget.l10n.apply),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9,
                ),
                itemCount: AppConstants.businessTypes.length,
                itemBuilder: (_, i) {
                  final t = AppConstants.businessTypes[i];
                  final sel = t['id'] == _selected;
                  final color = AppColors.forBusiness(t['id']);
                  return GestureDetector(
                    onTap: () => setState(() => _selected = t['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: sel ? color.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? color : AppColors.border, width: sel ? 2 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t['icon']!, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text(widget.l10n.businessTypeLabel(t),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                              color: sel ? color : AppColors.textSecondary),
                            textAlign: TextAlign.center, maxLines: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
