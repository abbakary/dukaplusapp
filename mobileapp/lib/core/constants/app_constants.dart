import '../config/api_config.dart';

class AppConstants {
  // API — resolved per platform in ApiConfig (see lib/core/config/api_config.dart)
  static String get apiBaseUrl => ApiConfig.baseUrl;
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage keys
  static const String kAccessToken   = 'duka_access';
  static const String kRefreshToken  = 'duka_refresh';
  static const String kUserData      = 'duka_user';
  static const String kBusinessType  = 'duka_biz_type';
  static const String kLanguage      = 'duka_lang';
  static const String kOfflineQueue  = 'duka_offline_queue';
  static const String kTokenExpires  = 'duka_token_expires';

  // Locale
  static const String defaultLocale  = 'sw';
  static const String currency       = 'TSh';
  static const String currencyCode   = 'TZS';

  // Business logic
  static const double defaultVatRate = 0.18;   // 18 % TRA Tanzania
  static const int    reorderLowPct  = 20;      // show low-stock when <= 20 % of reorder
  static const int    expiryWarnDays = 30;      // warn if expiring within 30 days
  static const double maxDiscountPct = 15.0;    // max cashier discount

  // SaaS plans
  static const String planStarter   = 'starter';
  static const String planPro        = 'biashara_pro';
  static const String planEnterprise = 'enterprise_chain';

  // User roles
  static const String roleOwner      = 'vendor_owner';
  static const String roleStaff      = 'vendor_staff';
  static const String roleSuperAdmin = 'super_admin';

  // Business types
  static const List<Map<String, String>> businessTypes = [
    {'id': 'pharmacy',    'label_en': 'Pharmacy',          'label_sw': 'Duka la Dawa',        'icon': '💊'},
    {'id': 'supermarket', 'label_en': 'Supermarket',        'label_sw': 'Supermarket',          'icon': '🏬'},
    {'id': 'retail',      'label_en': 'General Retail',     'label_sw': 'Rejareja / Duka',      'icon': '🛒'},
    {'id': 'hardware',    'label_en': 'Hardware & Building', 'label_sw': 'Vifaa vya Ujenzi',    'icon': '🔧'},
    {'id': 'electronics', 'label_en': 'Electronics',        'label_sw': 'Vifaa vya Umeme',      'icon': '📱'},
    {'id': 'auto_parts',  'label_en': 'Auto Spare Parts',   'label_sw': 'Vipuri vya Magari',   'icon': '🚗'},
    {'id': 'fashion',     'label_en': 'Fashion & Clothing', 'label_sw': 'Nguo na Mitindo',      'icon': '👗'},
    {'id': 'agrovet',     'label_en': 'Agrovet',            'label_sw': 'Agrovet',              'icon': '🌾'},
    {'id': 'beauty',      'label_en': 'Beauty & Cosmetics', 'label_sw': 'Urembo na Cosmetics',  'icon': '💄'},
    {'id': 'salon',       'label_en': 'Salon / Barbershop', 'label_sw': 'Saluni / Kinyozi',     'icon': '💇'},
    {'id': 'restaurant',  'label_en': 'Restaurant & Cafe',  'label_sw': 'Mgahawa',              'icon': '🍽️'},
    {'id': 'stationery',  'label_en': 'Stationery',         'label_sw': 'Vifaa vya Ofisi',      'icon': '📚'},
    {'id': 'furniture',   'label_en': 'Furniture',          'label_sw': 'Samani',               'icon': '🪑'},
    {'id': 'service',     'label_en': 'General Service',    'label_sw': 'Huduma za Jumla',      'icon': '💼'},
    {'id': 'mixed',       'label_en': 'Mixed Business',     'label_sw': 'Biashara Mchanganyiko','icon': '🏢'},
  ];

  // Payment methods
  static const List<Map<String, String>> paymentMethods = [
    {'id': 'cash',     'label': 'Cash',          'icon': '💵'},
    {'id': 'mpesa',    'label': 'M-Pesa',        'icon': '📲'},
    {'id': 'airtel',   'label': 'Airtel Money',  'icon': '📱'},
    {'id': 'tigopesa', 'label': 'Tigo Pesa',     'icon': '📱'},
    {'id': 'card',     'label': 'Card',          'icon': '💳'},
    {'id': 'credit',   'label': 'Credit',        'icon': '🏦'},
  ];

  // Staff roles
  static const List<String> staffRoles = [
    'Owner', 'Manager', 'Pharmacist', 'Cashier', 'Storekeeper', 'Accountant',
  ];
}
