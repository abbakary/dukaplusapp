import 'package:dio/dio.dart';

/// True only for transport/network failures — not 401/403/500 from the server.
bool isNetworkError(Object error) {
  if (error is! DioException) return false;
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    case DioExceptionType.unknown:
      final msg = error.message?.toLowerCase() ?? '';
      return msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('connection') ||
          msg.contains('failed host lookup');
    default:
      return false;
  }
}

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is Map && detail['message'] is String) {
        return detail['message'] as String;
      }
    }
    return error.message ?? 'Request failed';
  }
  return error.toString();
}
