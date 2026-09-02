import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/customer_model.dart';
import '../../data/models/product_model.dart';
import 'tenant_cache_io.dart' if (dart.library.html) 'tenant_cache_web.dart';

/// Tenant product/customer cache — files on mobile, SharedPreferences on web.
class TenantCacheService {
  Future<void> saveProducts(String tenantId, List<Product> products) async {
    final payload = jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'items': products.map((p) => p.toJson()).toList(),
    });
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey(tenantId, 'products'), payload);
      return;
    }
    await saveTenantCacheFile(tenantId, 'products', payload);
  }

  Future<List<Product>?> loadProducts(String tenantId) async {
    try {
      final raw = kIsWeb
          ? (await SharedPreferences.getInstance())
              .getString(_prefKey(tenantId, 'products'))
          : await readTenantCacheFile(tenantId, 'products');
      if (raw == null || raw.isEmpty) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final items = j['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCustomers(String tenantId, List<Customer> customers) async {
    final payload = jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'items': customers.map((c) => c.toJson()).toList(),
    });
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey(tenantId, 'customers'), payload);
      return;
    }
    await saveTenantCacheFile(tenantId, 'customers', payload);
  }

  Future<List<Customer>?> loadCustomers(String tenantId) async {
    try {
      final raw = kIsWeb
          ? (await SharedPreferences.getInstance())
              .getString(_prefKey(tenantId, 'customers'))
          : await readTenantCacheFile(tenantId, 'customers');
      if (raw == null || raw.isEmpty) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final items = j['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<String?> productsSavedAt(String tenantId) async {
    try {
      final raw = kIsWeb
          ? (await SharedPreferences.getInstance())
              .getString(_prefKey(tenantId, 'products'))
          : await readTenantCacheFile(tenantId, 'products');
      if (raw == null || raw.isEmpty) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return j['savedAt']?.toString();
    } catch (_) {
      return null;
    }
  }

  String _prefKey(String tenantId, String suffix) {
    final safe = tenantId.replaceAll(RegExp(r'[^\w.-]'), '_');
    return 'duka_cache_${safe}_$suffix';
  }
}
