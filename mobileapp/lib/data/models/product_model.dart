import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String name;
  final String category;
  final String sku;
  final double price;
  final double cost;
  final double stock;
  final double reorderPoint;
  final String unit;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String businessType;
  final bool requiresPrescription;
  final String? supplier;
  final String? vatType;
  final String? description;
  final String? location;
  final bool isDrug;
  final Map<String, double> branchStock;
  final Map<String, dynamic> metadata;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.price,
    required this.cost,
    required this.stock,
    required this.reorderPoint,
    required this.unit,
    this.batchNumber,
    this.expiryDate,
    required this.businessType,
    this.requiresPrescription = false,
    this.supplier,
    this.vatType,
    this.description,
    this.location,
    this.isDrug = false,
    this.branchStock = const {},
    this.metadata = const {},
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id:           j['id']?.toString() ?? '',
    name:         j['name']?.toString() ?? '',
    category:     j['category']?.toString() ?? '',
    sku:          j['sku']?.toString() ?? '',
    price:        _d(j['price']),
    cost:         _d(j['cost'] ?? j['buying_price']),
    stock:        _d(j['stock'] ?? j['quantity']),
    reorderPoint: _d(j['reorder_point'] ?? j['reorder_level']),
    unit:         j['unit']?.toString() ?? 'pcs',
    batchNumber:  j['batch_number']?.toString(),
    expiryDate:   j['expiry_date'] != null ? DateTime.tryParse(j['expiry_date'].toString()) : null,
    businessType: j['business_type']?.toString() ?? 'retail',
    requiresPrescription: j['requires_prescription'] == true,
    supplier:     j['supplier']?.toString(),
    vatType:      j['vat_type']?.toString(),
    description:  j['description']?.toString(),
    location:     j['location']?.toString(),
    isDrug:       j['is_drug'] == true,
    metadata: _readMap(j['metadata_json'] ?? j['metadata']),
    branchStock: _readDoubleMap(j['branch_stock']),
  );

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static Map<String, double> _readDoubleMap(dynamic value) {
    final map = _readMap(value);
    return map.map((k, v) => MapEntry(k, _d(v)));
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'category': category, 'sku': sku,
    'price': price, 'cost': cost, 'stock': stock,
    'reorder_point': reorderPoint, 'unit': unit,
    'batch_number': batchNumber,
    'expiry_date': expiryDate?.toIso8601String(),
    'business_type': businessType,
    'requires_prescription': requiresPrescription,
    'supplier': supplier, 'vat_type': vatType,
    'description': description, 'location': location,
    'is_drug': isDrug,
  };

  bool get isLowStock => stock <= reorderPoint;
  bool get isOutOfStock => stock <= 0;

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    return expiryDate!.difference(DateTime.now()).inDays <= 30;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  double get margin => cost > 0 ? ((price - cost) / cost * 100) : 0;
  double get profit => price - cost;

  Product copyWith({
    double? stock, double? price, double? cost, String? batchNumber,
    DateTime? expiryDate,
  }) => Product(
    id: id, name: name, category: category, sku: sku, unit: unit,
    reorderPoint: reorderPoint, businessType: businessType,
    requiresPrescription: requiresPrescription, supplier: supplier,
    vatType: vatType, description: description, location: location,
    isDrug: isDrug, branchStock: branchStock, metadata: metadata,
    price: price ?? this.price,
    cost: cost ?? this.cost,
    stock: stock ?? this.stock,
    batchNumber: batchNumber ?? this.batchNumber,
    expiryDate: expiryDate ?? this.expiryDate,
  );

  static double _d(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}
