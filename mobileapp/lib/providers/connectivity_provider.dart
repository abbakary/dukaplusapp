import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true);
  void setOnline(bool v) => state = v;
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>(
  (ref) => ConnectivityNotifier(),
);

final pendingSyncCountProvider = StateProvider<int>((ref) => 0);
