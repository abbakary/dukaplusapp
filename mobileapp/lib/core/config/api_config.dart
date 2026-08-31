import 'package:flutter/foundation.dart';

/// Resolves the API base URL for the current platform and build mode.
///
/// React web uses Vite's `/api` proxy → `http://localhost:8000`. Flutter must
/// hit the same local backend in debug, otherwise browser CORS blocks requests
/// to production and accounts created locally won't exist there.
///
/// Override for a physical device on LAN:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1`
class ApiConfig {
  ApiConfig._();

  static const String productionBaseUrl = 'https://api.dukaplus.co.tz/api/v1';
  static const String localBaseUrl = 'http://localhost:8000/api/v1';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';

  /// Optional override via `--dart-define=API_BASE_URL=...`
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kReleaseMode) return productionBaseUrl;
    if (kIsWeb) return localBaseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidEmulatorBaseUrl;
    }
    return localBaseUrl;
  }
}
