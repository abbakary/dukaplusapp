import 'package:flutter/foundation.dart';

/// Resolves the API base URL for the current platform and build mode.
///
/// Default: Railway production backend with demo sample data.
///
/// Override:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
///
/// Use local backend in debug:
///   flutter run --dart-define=USE_LOCAL_API=true
class ApiConfig {
  ApiConfig._();

  static const String railwayBaseUrl =
      'https://dukaplusbackend-production.up.railway.app/api/v1';

  static const String localBaseUrl = 'http://localhost:8000/api/v1';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';

  static const String _override = String.fromEnvironment('API_BASE_URL');
  static const bool _useLocalApi =
      bool.fromEnvironment('USE_LOCAL_API', defaultValue: false);

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (_useLocalApi) {
      if (kIsWeb) return localBaseUrl;
      if (defaultTargetPlatform == TargetPlatform.android) {
        return androidEmulatorBaseUrl;
      }
      return localBaseUrl;
    }
    return railwayBaseUrl;
  }

  static bool get isRailway => baseUrl.contains('railway.app');
}
