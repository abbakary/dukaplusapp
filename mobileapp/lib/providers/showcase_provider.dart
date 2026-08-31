import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/showcase_item.dart';
import 'api_provider.dart';

final showcaseProvider = FutureProvider<List<ShowcaseItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final data = await api.getShowcase();
    if (data.isEmpty) return ShowcaseItem.defaults;
    return data.map((e) => ShowcaseItem.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return ShowcaseItem.defaults;
  }
});
