import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_client.dart';

/// Singleton API client — shared across all providers
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
