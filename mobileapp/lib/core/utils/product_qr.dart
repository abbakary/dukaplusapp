import 'dart:convert';

import '../../data/models/product_model.dart';

class ProductQrPayload {
  final String id;
  final String sku;
  final String name;
  final double price;
  final String? batchNumber;
  final String? expiryDate;
  final String? category;

  const ProductQrPayload({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    this.batchNumber,
    this.expiryDate,
    this.category,
  });

  factory ProductQrPayload.fromProduct(Product p) => ProductQrPayload(
        id: p.id,
        sku: p.sku,
        name: p.name,
        price: p.price,
        batchNumber: p.batchNumber,
        expiryDate: p.expiryDate?.toIso8601String(),
        category: p.category,
      );
}

/// JSON payload — same format as web `getProductQRPayloadString`.
String getProductQrPayloadString(Product product) {
  final payload = ProductQrPayload.fromProduct(product);
  return jsonEncode({
    'id': payload.id,
    'sku': payload.sku,
    'name': payload.name,
    'price': payload.price,
    if (payload.batchNumber != null) 'batchNumber': payload.batchNumber,
    if (payload.expiryDate != null) 'expiryDate': payload.expiryDate,
    if (payload.category != null) 'category': payload.category,
  });
}

/// Compact fallback: DUKA:SKU:PRICE:ID
String getProductQrFallbackString(Product product) =>
    'DUKA:${product.sku}:${product.price.toStringAsFixed(0)}:${product.id}';

/// Parse scanned QR — mirrors web `parseScannedQRPayload`.
ProductQrPayload? parseScannedQrPayload(String scannedText) {
  if (scannedText.trim().isEmpty) return null;
  final trimmed = scannedText.trim();

  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      final m = jsonDecode(trimmed) as Map<String, dynamic>;
      return ProductQrPayload(
        id: m['id']?.toString() ?? '',
        sku: m['sku']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        price: double.tryParse(m['price']?.toString() ?? '0') ?? 0,
        batchNumber: m['batchNumber']?.toString(),
        expiryDate: m['expiryDate']?.toString(),
        category: m['category']?.toString(),
      );
    } catch (_) {}
  }

  if (trimmed.startsWith('DUKA:')) {
    final parts = trimmed.split(':');
    return ProductQrPayload(
      sku: parts.length > 1 ? parts[1] : '',
      price: parts.length > 2 ? (double.tryParse(parts[2]) ?? 0) : 0,
      id: parts.length > 3 ? parts[3] : '',
      name: '',
    );
  }

  return ProductQrPayload(id: '', sku: trimmed, name: '', price: 0);
}
