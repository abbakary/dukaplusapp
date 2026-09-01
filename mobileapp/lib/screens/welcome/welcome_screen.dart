import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_brand_logo.dart';

const _teal  = Color(0xFF0D9488);
const _navy  = Color(0xFF0F2347);
const _navy2 = Color(0xFF1A3A6B);

class _Feature {
  final IconData icon;
  final Color color;
  final String titleKey;
  final String descKey;
  const _Feature(this.icon, this.color, this.titleKey, this.descKey);
}

const _features = [
  _Feature(Icons.point_of_sale_rounded,   Color(0xFF0D9488), 'featurePos',      'featurePosDesc'),
  _Feature(Icons.inventory_2_rounded,     Color(0xFF2563EB), 'featureInventory', 'featureInventoryDesc'),
  _Feature(Icons.bar_chart_rounded,       Color(0xFF7C3AED), 'featureReports',   'featureReportsDesc'),
  _Feature(Icons.people_alt_rounded,      Color(0xFFDB2777), 'featureCustomers', 'featureCustomersDesc'),
  _Feature(Icons.wifi_off_rounded,        Color(0xFFD97706), 'featureOffline',   'featureOfflineDesc'),
  _Feature(Icons.account_balance_rounded, Color(0xFF059669), 'featureFinance',   'featureFinanceDesc'),
];

const _stats = [
  {'value': '10K+',  'label': 'Businesses'},
  {'value': '99.9%', 'label': 'Uptime'},
  {'value': '5★',    'label': 'Rating'},
];

// ─────────────────────────────────────────────────────────────────────────────
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _featureCtrl;
  late Animation<double>   _heroFade;
  late Animation<Offset>   _heroSlide;
  late Animation<double>   _featureFade;
  int _featureIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _heroCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    _featureCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _heroFade    = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide   = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));
    _featureFade = CurvedAnimation(parent: _featureCtrl, curve: Curves.easeOut);
    _heroCtrl.forward();
    _featureCtrl.forward();
    Future.delayed(const Duration(seconds: 3), _cycleFeature);
  }

  void _cycleFeature() {
    if (!mounted) return;
    _featureCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _featureIndex = (_featureIndex + 1) % _features.length);
      _featureCtrl.forward().then((_) =>
          Future.delayed(const Duration(seconds: 3), _cycleFeature));
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _featureCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = ref.watch(appLocalizationsProvider);
    final mq     = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final botPad = mq.padding.bottom;
    final screenW = mq.size.width;
    final screenH = mq.size.height;

    // Layout breakpoints
    final isCompact = screenH < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      // Use a pure scroll — no IntrinsicHeight, no Expanded fighting for space
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Gradient hero ────────────────────────────────────────
            _HeroSection(
              l10n:         l10n,
              topPad:       topPad,
              screenW:      screenW,
              isCompact:    isCompact,
              heroFade:     _heroFade,
              heroSlide:    _heroSlide,
              featureFade:  _featureFade,
              featureIndex: _featureIndex,
            ),
            // ── White CTA ────────────────────────────────────────────
            _CtaSection(
              l10n:      l10n,
              bottomPad: botPad,
              isCompact: isCompact,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Section
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final AppLocalizations l10n;
  final double topPad;
  final double screenW;
  final bool   isCompact;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final Animation<double> featureFade;
  final int featureIndex;

  const _HeroSection({
    required this.l10n, required this.topPad, required this.screenW,
    required this.isCompact, required this.heroFade, required this.heroSlide,
    required this.featureFade, required this.featureIndex,
  });

  @override
  Widget build(BuildContext context) {
    final vGap = isCompact ? 10.0 : 16.0;

    return Stack(
      children: [
        // Gradient background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_navy, _navy2, Color(0xFF2556A0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        // Decorative circles
        Positioned(
          top: -screenW * 0.28,
          right: -screenW * 0.18,
          child: Container(
            width: screenW * 0.65, height: screenW * 0.65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned(
          bottom: -screenW * 0.10,
          left: -screenW * 0.10,
          child: Container(
            width: screenW * 0.45, height: screenW * 0.45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _teal.withValues(alpha: 0.08),
            ),
          ),
        ),
        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(24, topPad + 14, 24, 28),
          child: FadeTransition(
            opacity: heroFade,
            child: SlideTransition(
              position: heroSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top bar: logo centered, lang on right ──────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered brand
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                      const AppBrandLogo(height: 44, width: 190, showShadow: true),
                        ],
                      ),
                      // Language button on the right edge
                      const Positioned(right: 0, child: _LangButton()),
                    ],
                  ),
                  SizedBox(height: vGap * 1.5),

                  // ── Badge pill ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _teal.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: _teal, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(l10n.welcomeBadge,
                          style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _teal)),
                      ],
                    ),
                  ),
                  SizedBox(height: vGap),

                  // ── Headline ──────────────────────────────────────
                  Text(l10n.welcomeTitle,
                    style: TextStyle(
                      fontSize: isCompact ? 24 : 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                    )),
                  SizedBox(height: isCompact ? 6 : 10),

                  // ── Subtitle ──────────────────────────────────────
                  Text(l10n.welcomeSubtitle,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 13,
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    )),
                  SizedBox(height: vGap),

                  // ── Stats row ─────────────────────────────────────
                  Row(
                    children: _stats.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s['value']!,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: isCompact ? 17 : 20,
                            )),
                          Text(s['label']!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10.5,
                            )),
                        ],
                      ),
                    )).toList(),
                  ),
                  SizedBox(height: vGap),

                  // ── Animated feature strip ────────────────────────
                  FadeTransition(
                    opacity: featureFade,
                    child: _FeatureHighlight(
                      feature: _features[featureIndex],
                      index:   featureIndex,
                      total:   _features.length,
                      l10n:    l10n,
                      compact: isCompact,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA Section (white bottom)
// ─────────────────────────────────────────────────────────────────────────────
class _CtaSection extends StatelessWidget {
  final AppLocalizations l10n;
  final double bottomPad;
  final bool   isCompact;

  const _CtaSection({
    required this.l10n, required this.bottomPad, required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      // Safe bottom padding — at least 20px, never more than needed
      padding: EdgeInsets.fromLTRB(
        24,
        isCompact ? 16 : 24,
        24,
        (bottomPad > 0 ? bottomPad : 0) + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feature grid — fixed-height, no expansion
          _FeatureGrid(l10n: l10n, compact: isCompact),
          SizedBox(height: isCompact ? 16 : 20),

          // Get started
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.getStarted,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Sign in
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => GoRouter.of(context).go('/login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy2,
                side: const BorderSide(color: Color(0xFFDDE3EC), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l10n.signIn,
                style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/terms'),
            child: Text(
              l10n.termsOfService,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language button
// ─────────────────────────────────────────────────────────────────────────────
class _LangButton extends ConsumerWidget {
  const _LangButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n  = ref.watch(appLocalizationsProvider);
    final isSw  = ref.watch(localeProvider) == AppLanguage.sw;
    return GestureDetector(
      onTap: () => _showLanguageSheet(context, ref, l10n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(isSw ? 'SW' : 'EN',
              style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(l10n.chooseLanguage,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                _LangTile(
                  flag: '🇹🇿', label: l10n.languageSw,
                  lang: AppLanguage.sw, ref: ref),
                _LangTile(
                  flag: '🇬🇧', label: l10n.languageEn,
                  lang: AppLanguage.en, ref: ref),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String flag;
  final String label;
  final AppLanguage lang;
  final WidgetRef ref;
  const _LangTile({
    required this.flag, required this.label,
    required this.lang,  required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(localeProvider) == lang;
    return Material(
      color: Colors.white,
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 22)),
        title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: active
            ? Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(
                  color: _teal, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 16),
              )
            : null,
        onTap: () {
          ref.read(localeProvider.notifier).setLanguage(lang);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated feature highlight
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureHighlight extends StatelessWidget {
  final _Feature feature;
  final int index;
  final int total;
  final AppLocalizations l10n;
  final bool compact;

  const _FeatureHighlight({
    required this.feature, required this.index,
    required this.total,   required this.l10n,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14, vertical: compact ? 8 : 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_title(l10n, feature.titleKey),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
                Text(_desc(l10n, feature.descKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 11,
                  )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Dot pagination
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(total, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width:  i == index ? 14 : 5,
              height: 5,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                color: i == index
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ],
      ),
    );
  }

  String _title(AppLocalizations l10n, String key) {
    switch (key) {
      case 'featurePos':       return l10n.featurePos;
      case 'featureInventory': return l10n.featureInventory;
      case 'featureReports':   return l10n.featureReports;
      case 'featureCustomers': return l10n.featureCustomers;
      case 'featureOffline':   return l10n.featureOffline;
      case 'featureFinance':   return l10n.featureFinance;
      default: return key;
    }
  }

  String _desc(AppLocalizations l10n, String key) {
    switch (key) {
      case 'featurePosDesc':       return l10n.featurePosDesc;
      case 'featureInventoryDesc': return l10n.featureInventoryDesc;
      case 'featureReportsDesc':   return l10n.featureReportsDesc;
      case 'featureCustomersDesc': return l10n.featureCustomersDesc;
      case 'featureOfflineDesc':   return l10n.featureOfflineDesc;
      case 'featureFinanceDesc':   return l10n.featureFinanceDesc;
      default: return key;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature grid — fixed height, never overflows
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureGrid extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;
  const _FeatureGrid({required this.l10n, this.compact = false});

  @override
  Widget build(BuildContext context) {
    // Fixed pixel height: 2 rows × cell height + 1 gap
    final cellH  = compact ? 66.0 : 76.0;
    final gap    = 10.0;
    final totalH = cellH * 2 + gap;

    return SizedBox(
      height: totalH,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   3,
          mainAxisExtent:   cellH,   // fixed cell height — avoids aspect-ratio issues
          crossAxisSpacing: gap,
          mainAxisSpacing:  gap,
        ),
        itemCount: _features.length,
        itemBuilder: (context, i) {
          final f = _features[i];
          return Container(
            decoration: BoxDecoration(
              color:        f.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: f.color.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize:      MainAxisSize.min,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color:        f.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(f.icon, color: f.color, size: 17),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(_shortTitle(l10n, f.titleKey),
                    textAlign: TextAlign.center,
                    maxLines:  2,
                    overflow:  TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      Color(0xFF1A2A4A),
                      height:     1.2,
                    )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _shortTitle(AppLocalizations l10n, String key) {
    switch (key) {
      case 'featurePos':       return l10n.featurePos;
      case 'featureInventory': return l10n.featureInventory;
      case 'featureReports':   return l10n.featureReports;
      case 'featureCustomers': return l10n.featureCustomers;
      case 'featureOffline':   return l10n.featureOffline;
      case 'featureFinance':   return l10n.featureFinance;
      default: return key;
    }
  }
}
