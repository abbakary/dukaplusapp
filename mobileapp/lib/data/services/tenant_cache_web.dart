Future<void> saveTenantCacheFile(
  String tenantId,
  String suffix,
  String payload,
) async {
  throw UnsupportedError('Use SharedPreferences branch on web');
}

Future<String?> readTenantCacheFile(String tenantId, String suffix) async {
  return null;
}
