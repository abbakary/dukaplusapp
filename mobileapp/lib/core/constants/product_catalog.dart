/// Product categories & units per business type — mirrors web businessEngine defaults.
class ProductCatalog {
  ProductCatalog._();

  static const _categories = <String, List<String>>{
    'pharmacy': [
      'Pain Relief', 'Antibiotics', 'Vitamins', 'First Aid', 'Skin Care', 'General',
    ],
    'supermarket': [
      'Food & Groceries', 'Beverages', 'Household', 'Personal Care', 'Frozen', 'General',
    ],
    'retail': [
      'Food & Groceries', 'Beverages', 'Household', 'Personal Care', 'Electronics', 'Other',
    ],
    'hardware': [
      'Plumbing', 'Electrical', 'Paints', 'Tools', 'Fasteners', 'General',
    ],
    'electronics': [
      'Mobile Phones', 'Accessories', 'Audio', 'Computers', 'Home Appliances', 'General',
    ],
    'auto_parts': [
      'Engine Parts', 'Brake System', 'Filters & Fluids', 'Electrical', 'Body Parts', 'General',
    ],
    'fashion': [
      'Men', 'Women', 'Children', 'Footwear', 'Accessories', 'General',
    ],
    'agrovet': [
      'Seeds', 'Fertilizers', 'Pesticides', 'Animal Feed', 'Veterinary', 'General',
    ],
    'beauty': [
      'Skincare', 'Hair Care', 'Makeup', 'Fragrance', 'Tools', 'General',
    ],
    'salon': [
      'Hair Products', 'Skin Care', 'Tools', 'Accessories', 'Services', 'General',
    ],
    'restaurant': [
      'Ingredients', 'Beverages', 'Packaging', 'Condiments', 'Frozen', 'General',
    ],
    'stationery': [
      'Paper', 'Writing', 'Office Supplies', 'Art', 'General',
    ],
    'furniture': [
      'Living Room', 'Bedroom', 'Office', 'Outdoor', 'General',
    ],
    'service': [
      'Consulting', 'Repairs', 'Installation', 'General',
    ],
    'mixed': [
      'General', 'Food', 'Household', 'Electronics', 'Other',
    ],
  };

  static const _units = <String, List<String>>{
    'pharmacy': ['tablets', 'capsules', 'bottles', 'sachets', 'boxes', 'pcs'],
    'supermarket': ['pcs', 'kg', 'g', 'liters', 'cartons', 'packs'],
    'retail': ['pcs', 'pairs', 'packs', 'cartons', 'kg'],
    'hardware': ['pcs', 'meters', 'kg', 'bags', 'liters', 'sheets', 'rolls'],
    'electronics': ['pcs', 'sets'],
    'auto_parts': ['pcs', 'sets', 'pairs'],
    'fashion': ['pcs', 'pairs', 'sets'],
    'agrovet': ['bags', 'kg', 'liters', 'bottles', 'sachets'],
    'beauty': ['pcs', 'bottles', 'tubes', 'packs'],
    'salon': ['service', 'session', 'hour', 'pcs'],
    'restaurant': ['plates', 'portions', 'kg', 'liters', 'pcs'],
    'stationery': ['pcs', 'packs', 'boxes', 'reams'],
    'furniture': ['pcs', 'sets'],
    'service': ['service', 'hour', 'session'],
    'mixed': ['pcs', 'service', 'kg', 'hours'],
  };

  static List<String> categoriesFor(String bizType) =>
      _categories[bizType] ?? _categories['retail']!;

  static List<String> unitsFor(String bizType) =>
      _units[bizType] ?? _units['retail']!;

  static String defaultCategory(String bizType) => categoriesFor(bizType).first;

  static String defaultUnit(String bizType) => unitsFor(bizType).first;

  /// Matches React: `SKU-${Date.now().slice(-4)}` with extra entropy.
  static String generateSku() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final suffix = ts.toString().substring(ts.toString().length - 4);
    return 'SKU-$suffix';
  }
}
