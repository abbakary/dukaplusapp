import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'showcase_video_platform_stub.dart'
    if (dart.library.html) 'showcase_video_platform_web.dart'
    if (dart.library.io) 'showcase_video_platform_mobile.dart';

/// Full-screen in-app video viewer — iframe on web, WebView on mobile/desktop.
class ShowcaseVideoSheet extends StatelessWidget {
  const ShowcaseVideoSheet({
    super.key,
    required this.title,
    required this.mediaUrl,
  });

  final String title;
  final String mediaUrl;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String mediaUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShowcaseVideoSheet(title: title, mediaUrl: mediaUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * (kIsWeb ? 0.65 : 0.72);
    return Container(
      height: height,
      margin: EdgeInsets.only(top: kIsWeb ? 24 : 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: buildShowcaseVideoPlayer(mediaUrl),
            ),
          ),
        ],
      ),
    );
  }
}
