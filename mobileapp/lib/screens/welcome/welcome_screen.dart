import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/showcase_item.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/showcase_provider.dart';
import '../../widgets/showcase_banner_carousel.dart';
import '../../widgets/showcase_network_image.dart';
import '../../widgets/showcase_video_sheet.dart';

const _teal = Color(0xFF0d9488);

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final showcaseAsync = ref.watch(showcaseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: showcaseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
          error: (_, __) => _WelcomeBody(l10n: l10n, items: ShowcaseItem.defaults),
          data: (items) => _WelcomeBody(l10n: l10n, items: items),
        ),
      ),
    );
  }
}

class _WelcomeBody extends ConsumerWidget {
  const _WelcomeBody({required this.l10n, required this.items});

  final AppLocalizations l10n;
  final List<ShowcaseItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = items.where((i) => i.isFeatured).firstOrNull ?? items.firstOrNull;
    final banners = items.where((i) => !i.isFeatured || i.id != featured?.id).toList();
    if (banners.isEmpty && featured != null && !featured.isFeatured) {
      banners.addAll(items);
    }

    void openItem(ShowcaseItem item) {
      if (item.isVideo) {
        ShowcaseVideoSheet.show(context, title: item.title, mediaUrl: item.mediaUrl);
      }
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(l10n.appName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.language_rounded, color: _teal),
                  onPressed: () => _showLanguageSheet(context, ref, l10n),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _teal.withOpacity(0.25)),
                  ),
                  child: Text(l10n.welcomeBadge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _teal)),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.welcomeTitle,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, color: Color(0xFF0f172a)),
                ),
                const SizedBox(height: 12),
                Text(l10n.welcomeSubtitle, style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text(l10n.getStarted, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => context.go('/login'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(l10n.signIn, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (featured != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Text(l10n.showcaseTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => openItem(featured),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ShowcaseNetworkImage(
                          imageUrl: featured.thumbnailUrl ?? featured.mediaUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(color: Colors.black26),
                        if (featured.isVideo)
                          const Center(child: Icon(Icons.play_circle_filled, color: Colors.white, size: 56)),
                        Positioned(
                          left: 14,
                          bottom: 12,
                          right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(featured.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                              if (featured.subtitle != null)
                                Text(featured.subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: TextButton.icon(
                onPressed: () => openItem(featured),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(l10n.watchDemo),
                style: TextButton.styleFrom(foregroundColor: _teal),
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            child: ShowcaseBannerCarousel(
              items: banners.isNotEmpty ? banners : items,
              l10n: l10n,
              onTap: openItem,
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.chooseLanguage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.languageSw),
              trailing: ref.watch(localeProvider) == AppLanguage.sw ? const Icon(Icons.check, color: _teal) : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLanguage(AppLanguage.sw);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.languageEn),
              trailing: ref.watch(localeProvider) == AppLanguage.en ? const Icon(Icons.check, color: _teal) : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLanguage(AppLanguage.en);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
