import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../data/models/showcase_item.dart';
import '../../l10n/app_localizations.dart';
import 'showcase_network_image.dart';
/// Mobile-native auto-scrolling banner carousel for showcase ads.
class ShowcaseBannerCarousel extends StatefulWidget {
  const ShowcaseBannerCarousel({
    super.key,
    required this.items,
    required this.l10n,
    this.onTap,
  });

  final List<ShowcaseItem> items;
  final AppLocalizations l10n;
  final void Function(ShowcaseItem item)? onTap;

  @override
  State<ShowcaseBannerCarousel> createState() => _ShowcaseBannerCarouselState();
}

class _ShowcaseBannerCarouselState extends State<ShowcaseBannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _index = 0; // used by page indicator state

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(
                widget.l10n.sponsored,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0d9488),
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                widget.l10n.swipeForMore,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => widget.onTap?.call(item),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ShowcaseNetworkImage(
                          imageUrl: item.isVideo && item.thumbnailUrl != null
                              ? item.thumbnailUrl!
                              : item.mediaUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                            ),
                          ),
                        ),
                        if (item.isVideo)
                          const Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                          ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              if (item.subtitle != null)
                                Text(
                                  item.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: SmoothPageIndicator(
            controller: _controller,
            count: widget.items.length,
            effect: const WormEffect(
              dotHeight: 6,
              dotWidth: 6,
              activeDotColor: Color(0xFF0d9488),
              dotColor: Color(0xFFD1D5DB),
            ),
          ),
        ),
      ],
    );
  }
}
