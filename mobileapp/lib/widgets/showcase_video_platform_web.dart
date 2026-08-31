import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'showcase_video_platform_stub.dart' show normalizeVideoEmbedUrl;

Widget buildShowcaseVideoPlayer(String mediaUrl) {
  final embedUrl = normalizeVideoEmbedUrl(mediaUrl);
  final viewType = 'showcase-video-${embedUrl.hashCode}';

  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => html.IFrameElement()
      ..src = embedUrl
      ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
      ..allowFullscreen = true
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%',
  );

  return HtmlElementView(viewType: viewType);
}
