import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/product_model.dart';
import '../models/customer_model.dart';

/// File-based tenant cache — supports large catalogs (IndexedDB equivalent on mobile).
class TenantCacheService {
  Future<File> _file(String tenantId, String suffix) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = tenantId.replaceAll(RegExp(r'[^\w.-]'), '_');
    return File('${dir.path}/duka_cache_${safe}_$suffix.json');
  }

  Future<void> saveProducts(String tenantId, List<Product> products) async {
    final file = await _file(tenantId, 'products');
    await file.writeAsString(jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'items': products.map((p) => p.toJson()).toList(),
    }));
  }

  Future<List<Product>?> loadProducts(String tenantId) async {
    try {
      final file = await _file(tenantId, 'products');
      if (!await file.exists()) return null;
      final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final items = j['items'] as List<dynamic>? ?? [];
      return items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCustomers(String tenantId, List<Customer> customers) async {
    final file = await _file(tenantId, 'customers');
    await file.writeAsString(jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'items': customers.map((c) => c.toJson()).toList(),
    }));
  }

  Future<List<Customer>?> loadCustomers(String tenantId) async {
    try {
      final file = await _file(tenantId, 'customers');
      if (!await file.exists()) return null;
      final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final items = j['items'] as List<dynamic>? ?? [];
      return items.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<String?> productsSavedAt(String tenantId) async {
    try {
      final file = await _file(tenantId, 'products');
      if (!await file.exists()) return null;
      final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return j['savedAt']?.toString();
    } catch (_) {
      return null;
    }
  }
}
