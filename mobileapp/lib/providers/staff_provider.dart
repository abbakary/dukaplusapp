import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/staff_model.dart';
import 'api_provider.dart';

final staffRefreshProvider = StateProvider<int>((ref) => 0);

final staffProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) async {
  ref.watch(staffRefreshProvider);
  final api = ref.read(apiClientProvider);
  final raw = await api.getStaff();
  return raw.map((e) => StaffMember.fromJson(e as Map<String, dynamic>)).where((s) => s.active).toList();
});
