import 'package:flutter/material.dart';

enum AppLanguage { sw, en }

/// Bilingual strings for the entire mobile app (Swahili default).
class AppLocalizations {
  const AppLocalizations(this.lang);

  final AppLanguage lang;
  bool get isSw => lang == AppLanguage.sw;
  Locale get locale => lang == AppLanguage.sw ? const Locale('sw') : const Locale('en');

  String t(String en, String sw) => isSw ? sw : en;

  String get appName => 'Duka+';
  String get loading => t('Loading…', 'Inapakia…');
  String get retry => t('Retry', 'Jaribu tena');
  String get cancel => t('Cancel', 'Ghairi');
  String get close => t('Close', 'Funga');
  String get save => t('Save', 'Hifadhi');
  String get apply => t('Apply', 'Tumia');
  String get ok => t('OK', 'Sawa');
  String get error => t('Error', 'Hitilafu');
  String get continueLabel => t('Continue', 'Endelea');
  String get back => t('Back', 'Rudi');
  String get search => t('Search', 'Tafuta');
  String get add => t('Add', 'Ongeza');
  String get total => t('Total', 'Jumla');
  String get items => t('items', 'bidhaa');
  String get today => t('Today', 'Leo');
  String get yesterday => t('Yesterday', 'Jana');

  String get welcomeBadge => t('Built for Tanzania', 'Imejengwa kwa Tanzania');
  String get welcomeTitle => t('Your business, refined.', 'Biashara yako, imara.');
  String get welcomeSubtitle => t(
    'POS, inventory, CRM, TRA EFD — one ERP for shops, pharmacies, hardware & more.',
    'POS, hifadhi, wateja, TRA EFD — mfumo mmoja kwa maduka, pharmacy na zaidi.',
  );
  String get getStarted => t('Get started', 'Anza sasa');
  String get signIn => t('Sign in', 'Ingia');
  String get showcaseTitle => t('See Duka+ in action', 'Angalia Duka+ inavyofanya kazi');
  String get showcaseSubtitle => t('Demo video & platform highlights', 'Video ya demo na vipengele vya jukwaa');
  String get watchDemo => t('Watch demo', 'Tazama demo');
  String get sponsored => t('Sponsored', 'Matangazo');
  String get swipeForMore => t('Swipe for more', 'Telezesha kuona zaidi');

  String get welcomeBack => t('Welcome back', 'Karibu tena');
  String get signInSubtitle => t('Sign in to your account', 'Ingia kwenye akaunti yako');
  String get demoAccountsHint => t(
    'Demo accounts (password: demo123) — tap to fill',
    'Akaunti za mfano (nenosiri: demo123) — gusa kujaza',
  );
  String get posTagline => t('POS & Business Management', 'POS & Usimamizi wa Biashara');
  String get email => t('Email address', 'Barua pepe');
  String get password => t('Password', 'Nenosiri');
  String get forgotPassword => t('Forgot password?', 'Umesahau nenosiri?');
  String get resetPassword => t('Reset Password', 'Weka upya Nenosiri');
  String get resetPasswordHint => t(
    'Contact your administrator or use the web portal to reset your password.',
    'Wasiliana na msimamizi au tumia tovuti kuweka upya nenosiri.',
  );
  String get noAccount => t("Don't have an account? ", 'Huna akaunti? ');
  String get register => t('Register', 'Jisajili');
  String get loginFailed => t('Login failed', 'Imeshindikana kuingia');
  String get invalidEmail => t('Enter a valid email', 'Weka barua pepe sahihi');
  String get enterPassword => t('Enter your password', 'Weka nenosiri lako');
  String get signOut => t('Sign Out', 'Ondoka');
  String get signOutConfirm => t('Are you sure you want to sign out?', 'Una uhakika unataka kuondoka?');

  String get registerBusiness => t('Register your business', 'Sajili biashara yako');
  String get stepOf => t('Step', 'Hatua');
  String get ofLabel => t('of', 'kati ya');
  String get accountStep => t('Account', 'Akaunti');
  String get businessTypeStep => t('Business type', 'Aina ya biashara');
  String get detailsStep => t('Shop details', 'Maelezo ya duka');
  String get businessDetails => t('Business details', 'Maelezo ya biashara');
  String get reviewStep => t('Review', 'Hakiki');
  String get fullName => t('Full Name', 'Jina kamili');
  String get phone => t('Phone', 'Simu');
  String get confirmPassword => t('Confirm Password', 'Thibitisha nenosiri');
  String get businessName => t('Business Name', 'Jina la biashara');
  String get location => t('Location', 'Mahali');
  String get tinNumber => t('TIN Number', 'Namba ya TIN');
  String get createAccount => t('Create Account', 'Unda akaunti');

  String navLabel(String key) {
    const en = {
      'home': 'Home', 'pos': 'POS', 'stock': 'Stock', 'clients': 'Clients',
      'reports': 'Reports', 'bi': 'Profit BI', 'pending': 'Pending Sales',
      'suppliers': 'Suppliers', 'expenses': 'Expenses', 'branches': 'Branches',
      'settings': 'Settings', 'credit': 'Credit', 'myStipend': 'My Stipend',
      'documents': 'Documents',
      'transactions': 'Sales & Docs',
    };
    const sw = {
      'home': 'Nyumbani', 'pos': 'POS', 'stock': 'Stoo', 'clients': 'Wateja',
      'reports': 'Ripoti', 'bi': 'Faida BI', 'pending': 'Yanasubiri Malipo',
      'suppliers': 'Wasambazaji', 'expenses': 'Matumizi', 'branches': 'Matawi',
      'settings': 'Mipangilio', 'credit': 'Mikopo', 'myStipend': 'Posho Yangu',
      'documents': 'Hati',
      'transactions': 'Mauzo & Hati',
    };
    return isSw ? (sw[key] ?? key) : (en[key] ?? key);
  }

  String get settings => t('Settings', 'Mipangilio');
  String get settingsSubtitle => t('Account & Preferences', 'Akaunti na Mapendeleo');
  String get businessConfiguration => t('Business Configuration', 'Usanidi wa Biashara');
  String get businessType => t('Business Type', 'Aina ya Biashara');
  String get notSet => t('Not set', 'Haijawekwa');
  String get vatSettings => t('VAT Settings', 'Mipangilio ya VAT');
  String get vatStandard => t('18% (TRA Standard)', '18% (Kiwango cha TRA)');
  String get application => t('Application', 'Programu');
  String get language => t('Language', 'Lugha');
  String get languageSw => t('Swahili', 'Kiswahili');
  String get languageEn => t('English', 'Kiingereza');
  String get chooseLanguage => t('Choose language', 'Chagua lugha');
  String get notifications => t('Notifications', 'Arifa');
  String get notificationsSubtitle => t('Low stock, expiry, credit alerts', 'Stoo chini, muda wa kuisha, arifa za mkopo');
  String get pinSecurity => t('PIN / Security', 'PIN / Usalama');
  String get pinSecuritySubtitle => t('Set staff PIN codes', 'Weka PIN za wafanyakazi');
  String get dataSync => t('Data & Sync', 'Data & Usawazishaji');
  String get syncData => t('Sync Data', 'Sawazisha Data');
  String get syncDataSubtitle => t('Sync offline records to server', 'Sawazisha rekodi za nje ya mtandao');
  String get exportData => t('Export Data', 'Hamisha Data');
  String get exportSubtitle => t('Export to CSV / PDF', 'Hamisha kwa CSV / PDF');
  String get about => t('About', 'Kuhusu');
  String get appVersion => t('App Version', 'Toleo la Programu');
  String get helpSupport => t('Help & Support', 'Msaada');
  String get helpSubtitle => t('Documentation and contact', 'Nyaraka na mawasiliano');
  String get profileEditWeb => t('Profile editing available on web portal', 'Kuhariri wasifu kwenye tovuti');

  String get dashboard => t('Dashboard', 'Dashbodi');
  String get dashboardSubtitle => t('Business overview', 'Muhtasari wa biashara');
  String get todaysSales => t("Today's Sales", 'Mauzo ya Leo');
  String get totalProducts => t('Total Products', 'Jumla ya Bidhaa');
  String get lowStock => t('Low Stock', 'Stoo Chini');
  String get overdueCredit => t('Overdue Credit', 'Mkopo Uliochelewa');
  String get recentSales => t('Recent Sales', 'Mauzo ya Hivi Karibuni');
  String get noSalesYet => t('No sales yet', 'Hakuna mauzo bado');
  String get quickActions => t('Quick Actions', 'Vitendo vya Haraka');

  String get pointOfSale => t('Point of Sale', 'Sehemu ya Mauzo');
  String get pay => t('Pay', 'Lipa');
  String get payNow => t('Take Payment & Finish', 'Lipa & Kamilisha');
  String get payNowHint => t('Normal sale — payment taken now', 'Mauzo ya kawaida — malipo sasa');
  String get saveAndNext => t('Park Sale (No Payment)', 'Hifadhi Bila Malipo');
  String get saveAndNextHint => t('Serve next customer — pay later', 'Mteja anayefuata — malipo baadaye');
  String get orderSummary => t('Order Summary', 'Muhtasari wa Agizo');
  String get clearAll => t('Clear all', 'Futa yote');
  String get cartEmpty => t('Cart is empty', 'Kikapu hakina bidhaa');
  String get outOfStock => t('OUT OF STOCK', 'HAKUNA STOO');
  String get lowStockBadge => t('LOW', 'CHINI');
  String get payment => t('Payment', 'Malipo');
  String get paymentMethod => t('Payment Method', 'Njia ya Malipo');
  String get amountTendered => t('Amount Tendered', 'Kiasi Kilicholipwa');
  String get changeDue => t('Change Due', 'Chenji');
  String get selectCustomer => t('Select Customer', 'Chagua Mteja');
  String get walkIn => t('Walk-in', 'Mteja wa taslimu');
  String get scanCode => t('Scan / Enter Code', 'Skani / Weka Kodi');
  String get barcodeSku => t('Barcode or SKU', 'Barcode au SKU');
  String get find => t('Find', 'Tafuta');
  String get print => t('Print', 'Chapisha');
  String get saleSaved => t(
        'Sale parked — complete payment under Pending Sales',
        'Mauzo yamehifadhiwa — kamilisha malipo kwenye Yanasubiri Malipo',
      );
  String get couldNotLoadProducts => t('Could not load products', 'Imeshindwa kupakia bidhaa');
  String get noProductFound => t('No product found for', 'Hakuna bidhaa kwa');
  String get added => t('Added', 'Imeongezwa');

  String paymentMethodLabel(String id) {
    const en = {'cash': 'Cash', 'mpesa': 'M-Pesa', 'airtel': 'Airtel Money', 'tigopesa': 'Tigo Pesa', 'card': 'Card', 'credit': 'Credit'};
    const sw = {'cash': 'Taslimu', 'mpesa': 'M-Pesa', 'airtel': 'Airtel Money', 'tigopesa': 'Tigo Pesa', 'card': 'Kadi', 'credit': 'Mkopo'};
    return isSw ? (sw[id] ?? id) : (en[id] ?? id);
  }

  String get customers => t('Customers', 'Wateja');
  String get customersSubtitle => t('CRM & Credit Management', 'CRM & Usimamizi wa Mkopo');
  String get noCustomers => t('No customers yet', 'Hakuna wateja bado');
  String get addFirstCustomer => t('Add your first customer', 'Ongeza mteja wako wa kwanza');
  String get addCustomer => t('Add Customer', 'Ongeza Mteja');
  String get outstandingBalance => t('Outstanding Balance', 'Salio la Deni');
  String get creditLimit => t('Credit Limit', 'Kikomo cha Mkopo');
  String get purchases => t('Purchases', 'Manunuzi');
  String get recordPayment => t('Record Payment', 'Rekodi Malipo');
  String get recordPaymentHint => t('Record payment via POS credit sale', 'Rekodi malipo kupitia mauzo ya mkopo POS');
  String get customerAdded => t('Customer added', 'Mteja ameongezwa');
  String get fullNameRequired => t('Full Name *', 'Jina kamili *');
  String get phoneRequired => t('Phone *', 'Simu *');
  String get emailOptional => t('Email (optional)', 'Barua pepe (hiari)');
  String get saveCustomer => t('Save Customer', 'Hifadhi Mteja');

  String get inventory => t('Inventory', 'Hifadhi');
  String get inventorySubtitle => t('Products & stock levels', 'Bidhaa na kiwango cha stoo');
  String get noProducts => t('No products found', 'Hakuna bidhaa');
  String get addProduct => t('Add Product', 'Ongeza Bidhaa');
  String get stock => t('Stock', 'Stoo');

  String get uncompletedSales => t('Pending Sales', 'Mauzo Yanayosubiri Malipo');
  String get pendingSubtitle => t('Sales waiting for payment — nothing is lost', 'Mauzo yanayosubiri malipo — hakuna kinachopotea');
  String get noPendingSales => t('No pending sales', 'Hakuna mauzo yanayosubiri');
  String get pendingHint => t('Use Park Sale (No Payment) in POS to hold a cart', 'Tumia Hifadhi Bila Malipo kwenye POS kuhifadhi kikapu');
  String get openPos => t('Open POS', 'Fungua POS');
  String get resumeInPos => t('Continue in POS', 'Endelea kwenye POS');
  String get quickComplete => t('Complete Payment', 'Kamilisha Malipo');
  String get paymentReference => t('Payment reference (optional)', 'Nambari ya malipo (hiari)');
  String get complete => t('Complete', 'Kamilisha');
  String get saleCompleted => t('Sale completed successfully', 'Mauzo yamekamilika');
  String get localDraft => t('CART', 'KIKAPU');

  String get reports => t('Reports & Analytics', 'Ripoti & Takwimu');
  String get reportsSubtitle => t('Sales insights and performance', 'Maelezo ya mauzo na utendaji');
  String get exportWeb => t('Full export available on web portal', 'Hamisho kamili kwenye tovuti');
  String get profitBi => t('Profit BI Analysis', 'Uchambuzi wa Faida BI');
  String get profitBiSubtitle => t('Live margins, P&L, category profit & cost savings', 'Faida, P&L, faida kwa kategoria');

  String get suppliers => t('Suppliers', 'Wasambazaji');
  String get suppliersSubtitle => t('Vendor management', 'Usimamizi wa wasambazaji');
  String get expenses => t('Expenses', 'Matumizi');
  String get expensesSubtitle => t('Track business costs', 'Fuata gharama za biashara');
  String get branches => t('Branches', 'Matawi');
  String get branchesSubtitle => t('Multi-location management', 'Usimamizi wa matawi mengi');
  String get noData => t('No data available', 'Hakuna data');

  String businessTypeLabel(Map<String, String> type) =>
      isSw ? (type['label_sw'] ?? type['label_en'] ?? '') : (type['label_en'] ?? '');

  String get goodMorning => t('Good morning', 'Habari za asubuhi');
  String get goodAfternoon => t('Good afternoon', 'Habari za mchana');
  String get goodEvening => t('Good evening', 'Habari za jioni');
  String get owner => t('Owner', 'Mmiliki');
  String get noNewNotifications => t('No new notifications', 'Hakuna arifa mpya');
  String get thisMonth => t('This Month', 'Mwezi Huu');
  String get thisWeek => t('this week', 'wiki hii');
  String get stockValue => t('Stock Value', 'Thamani ya Stoo');
  String get receivables => t('Receivables', 'Madeni Yanayodaiwa');
  String get payables => t('Payables', 'Madeni Yanayolipwa');
  String get tabCustomersDebt => t('Customers', 'Wateja');
  String get tabSuppliersDebt => t('Suppliers', 'Wasambazaji');
  String get tabPaymentHistory => t('History', 'Historia');
  String get partyCustomer => t('Customer', 'Mteja');
  String get partySupplier => t('Supplier', 'Msambazaji');
  String get totalReceivables => t('Total Receivables', 'Jumla ya Madeni ya Wateja');
  String get totalPayables => t('Total Payables', 'Jumla ya Madeni ya Wasambazaji');
  String get debtorsCount => t('With debt', 'Wana deni');
  String get suppliersOwed => t('Suppliers owed', 'Wasambazaji wana deni');
  String get searchSuppliersHint => t('Search supplier or category…', 'Tafuta msambazaji au kategoria…');
  String get creditManagement => t('Credit & Payables', 'Mikopo & Madeni');
  String get creditManagementSubtitle => t('Settle customer debts & supplier payables', 'Lipa madeni ya wateja na wasambazaji');
  String get settlementHistory => t('Settlement History', 'Historia ya Malipo');
  String get settleDebt => t('Settle Debt', 'Lipa Deni');
  String get paySupplier => t('Pay Supplier', 'Lipa Msambazaji');
  String get fullPayment => t('Full Payment', 'Malipo Kamili');
  String get partialPayment => t('Partial Payment', 'Malipo ya Sehemu');
  String get amountToPay => t('Amount to Pay', 'Kiasi cha Kulipa');
  String get confirmPayment => t('Confirm Payment', 'Thibitisha Malipo');
  String get paymentRecorded => t('Payment recorded successfully', 'Malipo yamerekodiwa');
  String get viewOnlyNoPermission => t('View only — no permission', 'Angalia tu — hakuna ruhusa');
  String get noOutstandingReceivables => t('No outstanding receivables', 'Hakuna madeni ya wateja');
  String get noOutstandingPayables => t('No outstanding payables', 'Hakuna madeni ya wasambazaji');
  String get deleteExpense => t('Delete expense?', 'Futa matumizi?');
  String get delete => t('Delete', 'Futa');
  String get expenseDeleted => t('Expense deleted', 'Matumizi yamefutwa');
  String get editExpense => t('Edit Expense', 'Hariri Matumizi');
  String get saveChanges => t('Save Changes', 'Hifadhi Mabadiliko');
  String get expiringSoon => t('Expiring Soon', 'Inakaribia Kuisha');
  String get revenueTrend => t('Revenue Trend', 'Mwenendo wa Mapato');
  String get viewReports => t('View Reports', 'Angalia Ripoti');
  String get paymentMethods => t('Payment Methods', 'Njia za Malipo');
  String get topProducts => t('Top Products', 'Bidhaa Bora');
  String get unknownProduct => t('Unknown product', 'Bidhaa haijulikani');
  String get seeAll => t('See All', 'Angalia Zote');
  String get newSale => t('New Sale', 'Mauzo Mapya');
  String get pending => t('Pending', 'Yanasubiri');
  String transactionsCount(int n) => t('$n transactions', 'miamala $n');
  String itemsCount(int n) => t('$n items', 'bidhaa $n');
  String unitsSold(num n) => t('${n.toStringAsFixed(0)} units sold', 'imeuzwa ${n.toStringAsFixed(0)}');
  String thisWeekAmount(String amount) => t('$amount this week', '$amount wiki hii');

  String get searchCustomersHint => t('Search by name, phone, email...', 'Tafuta kwa jina, simu, barua pepe...');
  String get summaryTotal => t('Total', 'Jumla');
  String get withDebt => t('With Debt', 'Wana Deni');
  String get overdue => t('Overdue', 'Imechelewa');
  String owesAmount(String amount) => t('Owes $amount', 'Anadai $amount');
  String daysOverdue(int d) => t('${d}d overdue', 'imechelewa siku $d');
  String get noDebt => t('No debt', 'Hakuna deni');
  String pointsCount(int n) => t('$n pts', 'alama $n');
  String get address => t('Address', 'Anwani');
  String get loyaltyTier => t('Loyalty Tier', 'Kiwango cha Uaminifu');
  String get points => t('Points', 'Alama');
  String get totalPurchases => t('Total Purchases', 'Jumla ya Manunuzi');
  String get lastPurchase => t('Last Purchase', 'Manunuzi ya Mwisho');
  String totalPurchasesAmount(String amount) => t('Total purchases: $amount', 'Jumla ya manunuzi: $amount');
  String get requiredField => t('Required', 'Inahitajika');
  String get enterValidPhone => t('Enter valid phone', 'Weka simu sahihi');

  String get uncompletedTransactions => t('Pending Sales Queue', 'Foleni ya Mauzo Yanayosubiri');
  String needAttentionCount(int n) => t(
        '$n sale(s) awaiting payment. Nothing is lost.',
        'mauzo $n yanasubiri malipo. Hakuna kinachopotea.',
      );
  String get localDrafts => t('In-Progress Carts', 'Vikapu Vinavyoendelea');
  String get serverPending => t('Awaiting Payment', 'Yanasubiri Malipo');
  String get genericCustomer => t('Customer', 'Mteja');
  String itemsUnits(int items, String units) => t('$items items · $units units', 'bidhaa $items · vitengo $units');
  String get walkInCustomer => t('Walk-in Customer', 'Mteja wa Taslimu');
  String failedMessage(String e) => t('Failed: $e', 'Imeshindikana: $e');
  String paymentLabel(String method, String amount) => t('Payment: $method · $amount', 'Malipo: $method · $amount');

  String get stockAndProducts => t('Stock & Products', 'Stoo & Bidhaa');
  String get allProducts => t('All Products', 'Bidhaa Zote');
  String get expiring => t('Expiring', 'Inaisha');
  String get searchProductsHint => t('Search by name, SKU, category...', 'Tafuta kwa jina, SKU, kategoria...');
  String get noLowStockItems => t('No low stock items', 'Hakuna bidhaa zenye stoo chini');
  String get noExpiringItems => t('No expiring items', 'Hakuna bidhaa zinazoisha');
  String get noProductsYet => t('No products yet', 'Hakuna bidhaa bado');
  String get addFirstProduct => t('Add your first product', 'Ongeza bidhaa yako ya kwanza');
  String get expired => t('EXPIRED', 'IMEISHA');
  String get expiringBadge => t('EXPIRING', 'INAKARIBIA');
  String get outBadge => t('OUT', 'IMEISHA');
  String get okBadge => t('OK', 'SAWA');
  String batchLabel(String batch) => t('Batch: $batch', 'Kundi: $batch');
  String expLabel(String date) => t('Exp: $date', 'Muda: $date');
  String get adjustStock => t('Adjust Stock', 'Rekebisha Stoo');
  String currentStock(String qty, String unit) => t('Current: $qty $unit', 'Sasa: $qty $unit');
  String get changeQty => t('Change (+/-)', 'Badilisha (+/-)');
  String get reason => t('Reason', 'Sababu');
  String get reset => t('Reset', 'Weka Upya');
  String get manualAdjustment => t('Manual adjustment', 'Marekebisho ya mkono');
  String get stockUpdated => t('Stock updated', 'Stoo imesasishwa');
  String get productUpdated => t('Product updated', 'Bidhaa imesasishwa');
  String get productAdded => t('Product added', 'Bidhaa imeongezwa');
  String get edit => t('Edit', 'Hariri');
  String editProduct(String name) => t('Edit $name', 'Hariri $name');
  String get sellingPrice => t('Selling Price', 'Bei ya Uuzaji');
  String get costPrice => t('Cost Price', 'Bei ya Gharama');
  String get margin => t('Margin', 'Faida');
  String get reorderPoint => t('Reorder Point', 'Kiwango cha Kuagiza');
  String get batch => t('Batch', 'Kundi');
  String get expiry => t('Expiry', 'Muda wa Kuisha');
  String get supplier => t('Supplier', 'Msambazaji');
  String get filterProducts => t('Filter Products', 'Chuja Bidhaa');
  String get lowStockOnly => t('Low Stock Only', 'Stoo Chini Tu');
  String get expiringItems => t('Expiring Items', 'Bidhaa Zinazoisha');
  String get productNameRequired => t('Product Name *', 'Jina la Bidhaa *');
  String get sku => t('SKU', 'SKU');
  String get category => t('Category', 'Kategoria');
  String get openingStock => t('Opening Stock', 'Stoo ya Mwanzo');
  String get saveProduct => t('Save Product', 'Hifadhi Bidhaa');

  String get week => t('Week', 'Wiki');
  String get year => t('Year', 'Mwaka');
  String salesCount(int n) => t('$n sales', 'mauzo $n');
  String get revenueTrend7Days => t('Revenue Trend (7 Days)', 'Mwenendo wa Mapato (Siku 7)');
  String get paymentMethodsBreakdown => t('Payment Methods Breakdown', 'Muhtasari wa Njia za Malipo');
  String get somethingWentWrong => t('Something went wrong', 'Kuna hitilafu');

  String get procurementPayables => t('Procurement & Payables', 'Ununuzi & Madeni');
  String get noSuppliersYet => t('No suppliers yet', 'Hakuna wasambazaji bado');
  String get addFirstSupplier => t('Add your first supplier', 'Ongeza msambazaji wako wa kwanza');
  String get paidUp => t('Paid up', 'Imelipwa');
  String get createPO => t('Create PO', 'Unda Agizo');
  String get addSupplier => t('Add Supplier', 'Ongeza Msambazaji');
  String get companyNameRequired => t('Company Name *', 'Jina la Kampuni *');
  String get contactPerson => t('Contact Person', 'Mhusika');
  String get saveSupplier => t('Save Supplier', 'Hifadhi Msambazaji');
  String get supplierAdded => t('Supplier added', 'Msambazaji ameongezwa');
  String get createPurchaseOrder => t('Create Purchase Order', 'Unda Agizo la Ununuzi');
  String get createPOHint => t('Select a supplier and add items to create a PO.', 'Chagua msambazaji na ongeza bidhaa kuunda agizo.');
  String get sendPurchaseOrder => t('Send Purchase Order', 'Tuma Agizo la Ununuzi');

  String get expensesPayroll => t('Expenses & Payroll', 'Matumizi & Mishahara');
  String get costTrackingSubtitle => t('Cost tracking and staff payments', 'Fuata gharama na malipo ya wafanyakazi');
  String get totalExpenses => t('Total Expenses', 'Jumla ya Matumizi');
  String recordsCount(int n) => t('$n records', 'rekodi $n');
  String get noExpensesRecorded => t('No expenses recorded', 'Hakuna matumizi yaliyorekodiwa');
  String get startRecordingExpenses => t('Start recording your business expenses', 'Anza kurekodi matumizi ya biashara');
  String get addExpense => t('Add Expense', 'Ongeza Matumizi');
  String get recordExpense => t('Record Expense', 'Rekodi Matumizi');
  String get titleRequired => t('Title *', 'Kichwa *');
  String get amountRequired => t('Amount *', 'Kiasi *');
  String get recipientVendor => t('Recipient / Vendor', 'Mpokeaji / Muuzaji');
  String get expenseRecorded => t('Expense recorded', 'Matumizi yamerekodiwa');
  String get cashDrawer => t('Cash Drawer', 'Sanduku la Taslimu');
  String get mpesaTill => t('M-Pesa Till', 'Till ya M-Pesa');
  String get bankTransfer => t('Bank Transfer', 'Uhamisho wa Benki');

  String get branchManagement => t('Branch Management', 'Usimamizi wa Matawi');
  String get multiLocationOverview => t('Multi-location overview', 'Muhtasari wa matawi mengi');
  String get addBranchesWeb => t('Add branches via the web portal', 'Ongeza matawi kupitia tovuti');
  String get noBranchesYet => t('No branches yet', 'Hakuna matawi bado');
  String get addFirstBranch => t('Add your first branch location', 'Ongeza tawi lako la kwanza');
  String get totalBranches => t('Total Branches', 'Jumla ya Matawi');
  String get active => t('Active', 'Hai');
  String get staff => t('Staff', 'Wafanyakazi');
  String get monthlyRevenue => t('Monthly Revenue', 'Mapato ya Mwezi');
  String get dailyRevenue => t('Daily Revenue', 'Mapato ya Siku');
  String managerLabel(String name) => t('Manager: $name', 'Msimamizi: $name');
  String get stockTransfersWeb => t('Stock transfers available on web portal', 'Uhamisho wa stoo unapatikana kwenye tovuti');
  String get transferStock => t('Transfer Stock', 'Hamisha Stoo');
  String get manage => t('Manage', 'Simamia');

  String get profitAnalysis => t('Profit Analysis', 'Uchambuzi wa Faida');
  String get biLiveSubtitle => t('Live BI from sales, stock & expenses', 'BI ya moja kwa moja kutoka mauzo, stoo na matumizi');
  String get thisQuarter => t('This Quarter', 'Robo Hii');
  String get thisYear => t('This Year', 'Mwaka Huu');
  String get allTime => t('All Time', 'Muda Wote');
  String errorLoadingBi(String e) => t('Error loading BI data: $e', 'Hitilafu kupakia data ya BI: $e');
  String get quarter => t('Quarter', 'Robo');
  String get allTimeLower => t('All time', 'Muda wote');
  String get month => t('Month', 'Mwezi');
  String get monthly => t('Monthly', 'Kwa Mwezi');
  String performanceLabel(String range) => t('$range performance', 'utendaji wa $range');
  String get grossSales => t('Gross Sales', 'Mauzo Jumla');
  String get netProfit => t('Net Profit', 'Faida Halisi');
  String get cogs => t('COGS', 'Gharama ya Bidhaa');
  String get opex => t('OPEX', 'Matumizi ya Uendeshaji');
  String get opexLedger => t('1. OPEX Ledger', '1. Daftari la Matumizi');
  String get dailyStipends => t('2. Daily Stipends', '2. Posho za Kila Siku');
  String get monthlyPayroll => t('3. Monthly Payroll', '3. Mishahara ya Mwezi');
  String get todayLabel => t('Today', 'Leo');
  String get confirmAllowance => t('Confirm stipend', 'Thibitisha posho');
  String get editRates => t('Edit rates', 'Badili viwango');
  String get paidStatus => t('Paid', 'Imelipwa');
  String get awaitingPayment => t('Ready to pay', 'Tayari kulipwa');
  String get noPermissionPayroll => t('View only — owner/manager can pay', 'Angalia tu — mmiliki/meneja ndiyo wanaweza kulipa');
  String get noPermissionAllowances => t('View only — owner/manager can configure', 'Angalia tu — mmiliki/meneja ndiyo wanaweza kusanidi');
  String get payrollProcessed => t('Payroll processed', 'Mshahara umelipwa');
  String get foodAllowance => t('Food', 'Chakula');
  String get transportAllowance => t('Transport', 'Nauli');
  String get baseSalary => t('Base salary', 'Mshahara msingi');
  String get grossMargin => t('Gross Margin', 'Faida Jumla');
  String momChange(String arrow, String pct) => t('$arrow $pct% MoM', '$arrow $pct% kulingana na mwezi uliopita');
  String marginPercent(String pct) => t('$pct% margin', 'faida $pct%');
  String percentOfSales(String pct) => t('$pct% of sales', '$pct% ya mauzo');
  String get monthlyPlTrend => t('Monthly P&L Trend', 'Mwenendo wa Faida & Hasara');
  String get noPlData => t('No P&L data for this period', 'Hakuna data ya F&H kwa kipindi hiki');
  String get topCategoriesByProfit => t('Top Categories by Profit', 'Kategoria Bora kwa Faida');
  String marginShare(String margin, String share) => t('$margin% margin · $share% share', 'faida $margin% · sehemu $share%');
  String get productProfitLeaders => t('Product Profit Leaders', 'Bidhaa Bora kwa Faida');
  String marginSold(String margin, String sold) => t('$margin% margin · $sold sold', 'faida $margin% · imeuzwa $sold');
  String paretoClass(String c) => t('Class $c', 'Daraja $c');
  String get costSavingOpportunities => t('Cost-Saving Opportunities', 'Fursa za Kuokoa Gharama');

  String get whatBusinessType => t('What type of business?', 'Biashara ya aina gani?');
  String get tailorBusinessHint => t("We'll tailor everything to fit your needs.", 'Tutaboresha kila kitu kulingana na mahitaji yako.');
  String get yourFullName => t('Your full name', 'Jina lako kamili');
  String get tinOptional => t('TIN Number (optional)', 'Namba ya TIN (hiari)');
  String get createYourAccount => t('Create your account', 'Unda akaunti yako');
  String get phoneWithCode => t('Phone (+255...)', 'Simu (+255...)');
  String get minSixChars => t('Minimum 6 characters', 'Herufi 6 angalau');
  String get alreadyHaveAccount => t('Already have an account? ', 'Tayari una akaunti? ');
  String get registrationFailed => t('Registration failed', 'Usajili umeshindikana');
  String get fillRequiredFields => t('Please fill in required fields', 'Tafadhali jaza sehemu zinazohitajika');
  String stepOfTotal(int step, int total) => t('Step $step of $total', 'Hatua $step kati ya $total');

  String get saleComplete => t('Sale Complete!', 'Mauzo Yamekamilika!');
  String receiptNumber(String n) => t('Receipt #$n', 'Risiti #$n');
  String get view => t('View', 'Angalia');
  String get searchProductHint => t('Search product, SKU…', 'Tafuta bidhaa, SKU…');
  String get allCategories => t('All', 'Zote');
  String noResultsFor(String q) => t('No results for "$q"', 'Hakuna matokeo kwa "$q"');
  String get noProductsInCategory => t('No products in this category', 'Hakuna bidhaa katika kategoria hii');
  String restoredForCustomer(String name) => t('Restored for $name — continue sale', 'Imerejeshwa kwa $name — endelea mauzo');
  String get pendingSaleLoaded => t('Pending sale loaded — complete payment', 'Mauzo yaliyosalia yamepakuliwa — kamilisha malipo');
  String get draftRestored => t('Draft restored — continue sale', 'Rasimu imerejeshwa — endelea mauzo');
  String get subtotal => t('Subtotal', 'Jumla Ndogo');
  String get vat18 => t('VAT (18%)', 'VAT (18%)');

  String get documentTemplates => t('Document Templates', 'Violezo vya Hati');
  String get termsOfService => t('Terms of Service', 'Masharti ya Huduma');
  String get documentTemplatesSubtitle => t(
    'Delivery, order & invoice notes — 4 designs each',
    'Noti za uwasilishaji, agizo na ankara — miundo 4 kila moja',
  );
  String get discountSettings => t('Discount Settings', 'Mipangilio ya Punguzo');
  String get allowDiscounts => t('Allow discounts at POS', 'Ruhusu punguzo kwenye POS');
  String get showDiscountOnReceipts => t('Show discount on receipts', 'Onyesha punguzo kwenye risiti');
  String get showDiscountOnDocuments => t('Show discount on documents', 'Onyesha punguzo kwenye hati');
  String get maxDiscount => t('Max discount', 'Kikomo cha punguzo');
  String get discountEnabled => t('Discounts enabled', 'Punguzo limewashwa');
  String get discountDisabled => t('Discounts disabled', 'Punguzo limezimwa');
  String get discountPercent => t('Discount (%)', 'Punguzo (%)');
  String get grossSubtotal => t('Gross subtotal', 'Jumla kabla ya punguzo');
  String get discount => t('Discount', 'Punguzo');
  String get processing => t('Processing…', 'Inachakata…');
  String get completeSale => t('Take Payment & Finish', 'Lipa & Kamilisha');
  String get saleNotRecorded => t('Sale was not recorded', 'Mauzo hayakurekodiwa');
  String errorMessage(String e) => t('Error: $e', 'Hitilafu: $e');
  String itemCount(int n) => t('$n item${n == 1 ? '' : 's'}', 'bidhaa $n');
  String noProductFoundFor(String code) => t('No product found for "$code"', 'Hakuna bidhaa kwa "$code"');
  String addedProduct(String name) => t('Added $name', 'Imeongezwa $name');
  String get typeOrScanCode => t('Type or scan product code', 'Andika au skani kodi ya bidhaa');

  String get regenerateSku => t('Regenerate SKU', 'Tengeneza SKU upya');
  String get batchNumber => t('Batch Number', 'Nambari ya Batch');
  String get unit => t('Unit', 'Kipimo');
  String get sellInPos => t('Sell in POS', 'Uza kwenye POS');
  String get showQr => t('Show QR', 'Onyesha QR');
  String get downloadQr => t('Download QR', 'Pakua QR');
  String get downloadAllQr => t('Download All QR Labels', 'Pakua Lebo Zote za QR');
  String get qrShelfLabels => t('QR Shelf Labels', 'Lebo za QR za Rafu');
  String get qrSingleItem => t('Single Item', 'Bidhaa Moja');
  String qrAllItems(int n) => t('All Items ($n)', 'Bidhaa Zote ($n)');
  String get qrScanHint => t('Scan at POS to add this item to cart instantly', 'Skani kwenye POS kuongeza bidhaa kwenye kikapu mara moja');
  String get qrDownloaded => t('QR label saved', 'Lebo ya QR imehifadhiwa');
  String qrDownloadedCount(int n) => t('$n QR labels ready', 'Lebo $n za QR ziko tayari');
  String get autoSkuHint => t('Auto-generated — tap refresh to change', 'Imetengenezwa kiotomatiki — bonyeza kuibadilisha');

  // ── Welcome screen feature highlights ─────────────────────────────────────
  String get featurePos        => t('Point of Sale',   'Mauzo (POS)');
  String get featurePosDesc    => t('Fast checkout, barcode scan & receipts', 'Malipo ya haraka, skani na risiti');
  String get featureInventory  => t('Inventory',       'Stoo');
  String get featureInventoryDesc => t('Real-time stock, expiry & reorder alerts', 'Stoo ya wakati halisi na arifa');
  String get featureReports    => t('Reports',         'Ripoti');
  String get featureReportsDesc => t('Daily P&L, charts & export', 'Faida & hasara, grafu na usafirishaji');
  String get featureCustomers  => t('Customers',       'Wateja');
  String get featureCustomersDesc => t('CRM, credit management & loyalty', 'CRM, mikopo na uaminifu');
  String get featureOffline    => t('Works Offline',   'Inafanya Kazi Bila Mtandao');
  String get featureOfflineDesc => t('Full POS offline — syncs when online', 'POS kamili bila mtandao — inarudisha data');
  String get featureFinance    => t('Finance',         'Fedha');
  String get featureFinanceDesc => t('Expenses, payables & BI analytics', 'Matumizi, madeni na uchambuzi');

  // ── AI Assistant ──────────────────────────────────────────────────────────
  String get aiPro => t('AI Pro', 'AI Pro');
  String get aiAssistantTitle => t('Duka+ AI Assistant', 'Msaidizi Mahiri wa Duka+');
  String get aiAssistantSubtitle => t(
    'Data-driven insights • Swahili & English',
    'Ushauri kutoka data • Kiswahili & Kiingereza',
  );
  String get askQuestionPlaceholder => t(
    'Ask about sales, stock, customers…',
    'Uliza kuhusu mauzo, stoo, wateja…',
  );
  String get aiBrief => t('AI Brief', 'Ushauri wa AI');
  String get aiInsights => t('AI Insights', 'Uchambuzi wa AI');
  String get aiAnalyzing => t(
    'AI is analyzing your shop data…',
    'AI inachambua data ya duka lako…',
  );
  String get aiNetworkError => t(
    'Could not reach the AI service. Please try again.',
    'Mtandao umeshindwa kupokea jibu. Tafadhali jaribu tena.',
  );
  String get aiWelcomeMessage => t(
    'Hello! I am your **Duka+ AI Retail Assistant**. I can help you analyze revenue, forecast inventory restocking, score customer credit risks, or schedule calendar events. How can I help you today?',
    'Jambo! Mimi ni **Msaidizi Mahiri wa Duka+**. Ninaweza kukusaidia kuchambua mauzo, kutabiri bidhaa zilizopungua stoo, kusimamia madeni ya wateja, au kupanga matukio ya kalenda. Nikusaidie nini leo?',
  );
  String get aiDashboardPrompt => t(
    'Analyze today\'s dashboard — give me a profit report, low-stock items, and strategies to increase sales.',
    'Fanya uchambuzi wa dashibodi ya leo, unipe ripoti ya faida, bidhaa zilizoisha na mikakati ya kuongeza mauzo ya duka langu.',
  );
  String get aiReportsPrompt => t(
    'Give me a deep analysis of product sales by customer and location. Which products are stagnant and where are the profit opportunities this week?',
    'Fanya uchambuzi wa kina wa mauzo ya bidhaa kwa kila mteja na eneo. Niambie bidhaa gani inalala, wapi inauzwa kidogo, na nini mikakati ya kuongeza faida wiki hii.',
  );
  String get aiInventoryPrompt => t(
    'Which products are low stock and what should I reorder this week?',
    'Ni bidhaa gani zimepungua stoo na nini nifanye agizo wiki hii?',
  );
  List<String> get aiQuickChips => isSw
      ? const [
          '📊 Mauzo ya leo yapoje?',
          '📦 Ni bidhaa gani zimepungua stoo?',
          '👥 Wateja gani wana madeni makubwa?',
          '📅 Panga matukio ya wiki kwa AI',
        ]
      : const [
          '📊 How are today\'s sales?',
          '📦 Which products are low stock?',
          '👥 Who has overdue credit debt?',
          '📅 Schedule weekly events with AI',
        ];
}

extension AppLocalizationsX on AppLanguage {
  AppLocalizations get l10n => AppLocalizations(this);
}
