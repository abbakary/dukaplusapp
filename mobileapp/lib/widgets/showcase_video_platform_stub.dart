import 'package:flutter/widgets.dart';

Widget buildShowcaseVideoPlayer(String mediaUrl) {
  throw UnsupportedError('Showcase video player is not available on this platform.');
}

String normalizeVideoEmbedUrl(String mediaUrl) {
  var url = mediaUrl.trim();
  if (url.contains('youtube.com/watch')) {
    url = url.replaceFirst('watch?v=', 'embed/');
  }
  if ((url.contains('youtube') || url.contains('youtu.be')) && !url.contains('embed')) {
    final id = Uri.tryParse(url)?.queryParameters['v'];
    if (id != null) url = 'https://www.youtube.com/embed/$id';
  }
  if (url.contains('embed') && !url.contains('?')) {
    url = '$url?rel=0&modestbranding=1';
  }
  return url;
}
