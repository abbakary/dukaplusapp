class ShowcaseItem {
  final String id;
  final String title;
  final String? subtitle;
  final String mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? linkUrl;
  final int sortOrder;
  final bool isFeatured;

  const ShowcaseItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.linkUrl,
    this.sortOrder = 0,
    this.isFeatured = false,
  });

  bool get isVideo => mediaType == 'video';

  factory ShowcaseItem.fromJson(Map<String, dynamic> json) => ShowcaseItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle']?.toString(),
    mediaType: json['media_type']?.toString() ?? 'image',
    mediaUrl: json['media_url']?.toString() ?? '',
    thumbnailUrl: json['thumbnail_url']?.toString(),
    linkUrl: json['link_url']?.toString(),
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    isFeatured: json['is_featured'] == true,
  );

  static List<ShowcaseItem> defaults = [
    const ShowcaseItem(
      id: 'default-demo',
      title: 'Duka+ POS in 60 seconds',
      subtitle: 'Sell faster, track stock, manage credit',
      mediaType: 'video',
      mediaUrl: 'https://www.youtube.com/embed/ScMzIvxBSi4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800&auto=format&fit=crop',
      isFeatured: true,
    ),
    const ShowcaseItem(
      id: 'ad-1',
      title: 'TRA EFD Ready',
      subtitle: 'Receipts & VAT compliance for Tanzania',
      mediaType: 'image',
      mediaUrl: 'https://images.unsplash.com/photo-1454165804603-c3d57bc86b40?w=800&auto=format&fit=crop',
      sortOrder: 1,
    ),
    const ShowcaseItem(
      id: 'ad-2',
      title: 'Multi-branch Inventory',
      subtitle: 'Track stock across all locations',
      mediaType: 'image',
      mediaUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800&auto=format&fit=crop',
      sortOrder: 2,
    ),
  ];
}
