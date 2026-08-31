import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/offline_sync_service.dart';
import 'api_provider.dart';

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(ref.read(apiClientProvider));
});

final offlinePendingCountProvider = FutureProvider<int>((ref) async {
  return ref.read(offlineSyncServiceProvider).pendingCount();
});
