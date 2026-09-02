import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import 'api_client.dart';

class OfflineSyncService {
  OfflineSyncService(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.kOfflineQueue);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveQueue(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kOfflineQueue, jsonEncode(items));
  }

  Future<void> enqueue(Map<String, dynamic> item) async {
    final queue = await loadQueue();
    queue.add(item);
    await saveQueue(queue);
  }

  Future<int> pendingCount() async {
    final queue = await loadQueue();
    return queue.length;
  }

  Future<void> _replayItem(Map<String, dynamic> item) async {
    final type = item['entity_type']?.toString() ?? '';
    final action = item['action']?.toString() ?? '';
    final payload = Map<String, dynamic>.from(item['payload'] as Map? ?? {});

    switch (type) {
      case 'sale':
        if (action == 'create') await _api.createSale(payload);
        break;
      case 'product':
        if (action == 'create') {
          await _api.createProduct(payload);
        } else if (action == 'update') {
          await _api.updateProduct(item['entity_id'].toString(), payload);
        }
        break;
      case 'customer':
        if (action == 'create') {
          await _api.createCustomer(payload);
        } else if (action == 'update') {
          await _api.updateCustomer(item['entity_id'].toString(), payload);
        }
        break;
      case 'stock':
        if (action == 'adjust') await _api.adjustStock(payload);
        break;
      default:
        throw Exception('Unsupported sync item: $type/$action');
    }
  }

  Future<({int processed, int failed})> syncAll() async {
    final queue = await loadQueue();
    if (queue.isEmpty) return (processed: 0, failed: 0);

    try {
      final result = await _api.syncBatch(queue);
      final processed = (result['processed'] as num?)?.toInt() ?? queue.length;
      final failed = (result['failed'] as num?)?.toInt() ?? 0;
      if (failed == 0) {
        await saveQueue([]);
      } else if (processed > 0) {
        await saveQueue(queue.sublist(processed));
      }
      return (processed: processed, failed: failed);
    } catch (_) {
      /* batch unavailable */
    }

    final remaining = <Map<String, dynamic>>[];
    var processed = 0;
    var failed = 0;

    for (final item in queue) {
      try {
        await _replayItem(item);
        processed += 1;
      } catch (_) {
        remaining.add(item);
        failed += 1;
      }
    }

    await saveQueue(remaining);
    return (processed: processed, failed: failed);
  }
}
