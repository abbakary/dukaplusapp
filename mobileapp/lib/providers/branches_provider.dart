import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/branch_model.dart';
import 'api_provider.dart';

final branchesRefreshProvider = StateProvider<int>((ref) => 0);

final branchesProvider = FutureProvider.autoDispose<List<StoreBranch>>((ref) async {
  ref.watch(branchesRefreshProvider);
  final api = ref.read(apiClientProvider);
  final raw = await api.getBranches();
  return raw.map((e) => StoreBranch.fromJson(e as Map<String, dynamic>)).toList();
});

final activeBranchIdProvider = StateProvider<String?>((ref) => null);
