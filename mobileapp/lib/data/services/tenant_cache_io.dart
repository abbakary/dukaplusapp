import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> saveTenantCacheFile(
  String tenantId,
  String suffix,
  String payload,
) async {
  final dir = await getApplicationDocumentsDirectory();
  final safe = tenantId.replaceAll(RegExp(r'[^\w.-]'), '_');
  final file = File('${dir.path}/duka_cache_${safe}_$suffix.json');
  await file.writeAsString(payload);
}

Future<String?> readTenantCacheFile(String tenantId, String suffix) async {
  final dir = await getApplicationDocumentsDirectory();
  final safe = tenantId.replaceAll(RegExp(r'[^\w.-]'), '_');
  final file = File('${dir.path}/duka_cache_${safe}_$suffix.json');
  if (!await file.exists()) return null;
  return file.readAsString();
}
