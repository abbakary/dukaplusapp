import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/offline_sync_service.dart';
import 'api_provider.dart';

/// Online/offline flag — updated when API calls fail or succeed.
class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true);

  void setOnline(bool value) {
    if (state != value) state = value;
  }
}

final isOnlineProvider = StateNotifierProvider<ConnectivityNotifier, bool>(
  (ref) => ConnectivityNotifier(),
);

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(ref.read(apiClientProvider));
});

final syncRefreshProvider = StateProvider<int>((ref) => 0);

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  ref.watch(syncRefreshProvider);
  return ref.read(offlineSyncServiceProvider).pendingCount();
});
