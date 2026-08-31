import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'showcase_video_platform_stub.dart' show normalizeVideoEmbedUrl;

Widget buildShowcaseVideoPlayer(String mediaUrl) {
  final url = normalizeVideoEmbedUrl(mediaUrl);
  final isMp4 = url.endsWith('.mp4');

  final html = isMp4
      ? '''
<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
<style>body{margin:0;background:#000}video{width:100%;height:100vh}</style></head>
<body><video controls autoplay src="$url"></video></body></html>'''
      : '''
<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
<style>body{margin:0;background:#000}iframe{width:100%;height:100vh;border:0}</style></head>
<body><iframe src="$url" allowfullscreen allow="autoplay; encrypted-media"></iframe></body></html>''';

  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(html);

  return WebViewWidget(controller: controller);
}
