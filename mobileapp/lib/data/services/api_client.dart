import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class ApiClient {
  static const _storage = FlutterSecureStorage();
  late final Dio _dio;

  ApiClient() {
    final baseUrl = AppConstants.apiBaseUrl;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _dio.interceptors.addAll([
      _AuthInterceptor(_dio, _storage),
      _LogInterceptor(baseUrl),
    ]);
  }

  Dio get dio => _dio;

  List<dynamic> _unwrapItems(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return const [];
  }

  Map<String, dynamic> _unwrapPageMeta(dynamic data) {
    if (data is Map && data['meta'] is Map) {
      return Map<String, dynamic>.from(data['meta'] as Map);
    }
    return const {'total': 0, 'skip': 0, 'limit': 0, 'has_more': false};
  }

  Future<List<dynamic>> _fetchAllPages(
    Future<Response<dynamic>> Function(int skip, int limit) fetch,
    {int pageSize = 500, int maxItems = 5000}
  ) async {
    final all = <dynamic>[];
    var skip = 0;
    while (all.length < maxItems) {
      final res = await fetch(skip, pageSize);
      final items = _unwrapItems(res.data);
      all.addAll(items);
      final meta = _unwrapPageMeta(res.data);
      if (items.isEmpty || meta['has_more'] != true) break;
      skip += pageSize;
    }
    return all;
  }

  // ── Auth ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email, 'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/register', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final refresh = await _storage.read(key: AppConstants.kRefreshToken);
    if (refresh != null) {
      try {
        await _dio.post('/auth/logout', data: {'refresh_token': refresh});
      } catch (_) { /* ignore logout errors */ }
    }
    await _storage.deleteAll();
  }

  // ── Dashboard ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _dio.get('/dashboard/stats');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAnalyticsSnapshot({String range = 'month'}) async {
    final res = await _dio.get('/analytics/snapshot', queryParameters: {'range': range});
    return res.data as Map<String, dynamic>;
  }

  // ── Products ──────────────────────────────────────────────────────
  Future<List<dynamic>> getProducts({Map<String, dynamic>? params}) async {
    final res = await _dio.get('/products', queryParameters: params);
    return _unwrapItems(res.data);
  }

  Future<List<dynamic>> getAllProducts() => _fetchAllPages(
    (skip, limit) => _dio.get('/products', queryParameters: {'skip': skip, 'limit': limit}),
  );

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/products', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/products/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> adjustStock(Map<String, dynamic> data) async {
    await _dio.post('/stock/adjust', data: data);
  }

  Future<List<dynamic>> getStockMovements({String? productId}) async {
    final res = await _dio.get('/stock/movements',
        queryParameters: productId != null ? {'product_id': productId} : null);
    return res.data as List<dynamic>;
  }

  // ── Sales ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createSale(Map<String, dynamic> data) async {
    final res = await _dio.post('/sales', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSales({String? status, Map<String, dynamic>? params}) async {
    final qp = <String, dynamic>{...?params};
    if (status != null) qp['status'] = status;
    final res = await _dio.get('/sales', queryParameters: qp.isEmpty ? null : qp);
    return _unwrapItems(res.data);
  }

  // ── Customers ─────────────────────────────────────────────────────
  Future<List<dynamic>> getCustomers({String? search, Map<String, dynamic>? params}) async {
    final qp = <String, dynamic>{...?params};
    if (search != null) qp['search'] = search;
    final res = await _dio.get('/customers', queryParameters: qp.isEmpty ? null : qp);
    return _unwrapItems(res.data);
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    final res = await _dio.post('/customers', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/customers/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ── Suppliers ─────────────────────────────────────────────────────
  Future<List<dynamic>> getSuppliers() async {
    final res = await _dio.get('/suppliers');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> data) async {
    final res = await _dio.post('/suppliers', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSupplier(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/suppliers/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ── Branches ──────────────────────────────────────────────────────
  Future<List<dynamic>> getBranches() async {
    final res = await _dio.get('/branches');
    return res.data as List<dynamic>;
  }

  // ── Purchase Orders ───────────────────────────────────────────────
  Future<List<dynamic>> getPurchaseOrders() async {
    final res = await _dio.get('/purchase-orders');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createPurchaseOrder(Map<String, dynamic> data) async {
    final res = await _dio.post('/purchase-orders', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> receivePurchaseOrder(String id, {String? notes}) async {
    await _dio.post('/purchase-orders/$id/receive', data: {'notes': notes});
  }

  // ── Expenses ──────────────────────────────────────────────────────
  Future<List<dynamic>> getExpenses() async {
    final res = await _dio.get('/expenses');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    final res = await _dio.post('/expenses', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteExpense(String id) async {
    await _dio.delete('/expenses/$id');
  }

  Future<Map<String, dynamic>> claimDailyStipend({double? foodAmount, double? transportAmount}) async {
    final res = await _dio.post('/staff/me/claim-stipend', data: {
      if (foodAmount != null) 'food_amount': foodAmount,
      if (transportAmount != null) 'transport_amount': transportAmount,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateExpense(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/expenses/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ── Staff ─────────────────────────────────────────────────────────
  Future<List<dynamic>> getStaff() async {
    final res = await _dio.get('/staff');
    return res.data as List<dynamic>;
  }

  // ── Offline sync ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> syncBatch(List<Map<String, dynamic>> items) async {
    final res = await _dio.post('/sync/batch', data: {'items': items});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> finalizeSale(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/sales/$id/finalize', data: data);
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ── Platform showcase (public, no auth required) ───────────────────
  Future<List<dynamic>> getShowcase() async {
    final res = await _dio.get('/platform/showcase');
    return res.data as List<dynamic>;
  }

  // ── AI ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> aiChat({
    required String message,
    required String language,
    Map<String, dynamic>? shopContext,
    List<Map<String, dynamic>>? history,
  }) async {
    final res = await _dio.post('/ai/chat', data: {
      'message': message,
      'language': language,
      'shopContext': shopContext ?? {},
      'history': history ?? [],
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> aiSmartSchedule({
    required String language,
    String staffName = '',
    String role = '',
    String businessType = 'retail',
    List<Map<String, dynamic>>? existingEvents,
  }) async {
    final res = await _dio.post('/ai/smart-schedule', data: {
      'language': language,
      'staffName': staffName,
      'role': role,
      'businessType': businessType,
      'existingEvents': existingEvents ?? [],
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> aiCrossMatrix({
    required String language,
    List<Map<String, dynamic>>? locationSummary,
    List<Map<String, dynamic>>? customerTopPurchases,
    List<Map<String, dynamic>>? stagnantItems,
    String selectedLocation = 'all',
    String selectedCustomer = 'all',
  }) async {
    final res = await _dio.post('/ai/cross-matrix-analysis', data: {
      'language': language,
      'locationSummary': locationSummary ?? [],
      'customerTopPurchases': customerTopPurchases ?? [],
      'stagnantItems': stagnantItems ?? [],
      'selectedLocation': selectedLocation,
      'selectedCustomer': selectedCustomer,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ── Tenant settings & documents ───────────────────────────────────
  Future<Map<String, dynamic>> getTenantSettings() async {
    final res = await _dio.get('/tenant/settings');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateTenantSettings(Map<String, dynamic> data) async {
    final res = await _dio.put('/tenant/settings', data: data);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> uploadDocumentLogo(String imageBase64) async {
    final res = await _dio.post('/tenant/settings/logo', data: {'image_base64': imageBase64});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> removeDocumentLogo() async {
    final res = await _dio.delete('/tenant/settings/logo');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getDocumentCatalog() async {
    final res = await _dio.get('/tenant/documents/catalog');
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ── Token helpers ─────────────────────────────────────────────────
  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: AppConstants.kAccessToken,  value: access);
    await _storage.write(key: AppConstants.kRefreshToken, value: refresh);
  }

  static Future<String?> readAccessToken() =>
      _storage.read(key: AppConstants.kAccessToken);

  static Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.kAccessToken);
    await _storage.delete(key: AppConstants.kRefreshToken);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio, this._storage);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.kAccessToken);
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refresh = await _storage.read(key: AppConstants.kRefreshToken);
        if (refresh != null) {
          final res = await _dio.post('/auth/refresh',
              data: {'refresh_token': refresh},
              options: Options(headers: {'Authorization': null}));
          final data = res.data as Map<String, dynamic>;
          await ApiClient.saveTokens(
            data['access_token'].toString(), data['refresh_token'].toString());
          err.requestOptions.headers['Authorization'] =
              'Bearer ${data['access_token']}';
          final retried = await _dio.fetch(err.requestOptions);
          handler.resolve(retried);
          return;
        }
      } catch (_) {
        await _storage.deleteAll();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}

class _LogInterceptor extends Interceptor {
  final String baseUrl;
  bool _loggedBase = false;

  _LogInterceptor(this.baseUrl);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      if (!_loggedBase) {
        _loggedBase = true;
        // ignore: avoid_print
        print('[API] baseUrl=$baseUrl');
      }
      // ignore: avoid_print
      print('[API] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API ERR] ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}
