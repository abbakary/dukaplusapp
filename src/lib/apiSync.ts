import { api } from '@/lib/api';
import type {
  BusinessType,
  CalendarEvent,
  Customer,
  ExpenseItem,
  PlatformBroadcast,
  Product,
  PurchaseOrder,
  SaaSTransaction,
  SaleTransaction,
  StaffMember,
  StaffPermissions,
  StaffRole,
  StockMovement,
  StoreBranch,
  Supplier,
  TenantStore,
} from '@/types/v1';

/** FastAPI/Pydantic rejects `""` for optional date fields — omit when empty. */
export function optionalApiDate(value?: string | null): string | undefined {
  const trimmed = value?.trim();
  return trimmed ? trimmed : undefined;
}

export interface ApiSyncResult {
  businessType: BusinessType;
  businessName: string;
  plan?: import('@/types/v1').SaaSPlanTier;
  subscriptionExpiry?: string;
  tenantStatus?: string;
  products: Product[];
  customers: Customer[];
  customersFetchOk: boolean;
  suppliers: Supplier[];
  branches: StoreBranch[];
  expenses: ExpenseItem[];
  events: CalendarEvent[];
  staff: StaffMember[];
  purchaseOrders: PurchaseOrder[];
  sales: SaleTransaction[];
  stockMovements: StockMovement[];
}

export function mapProduct(p: Record<string, unknown>): Product {
  const meta = (p.metadata_json as Record<string, unknown>) ?? {};
  return {
    ...meta,
    id: p.id as string,
    name: p.name as string,
    category: p.category as string,
    sku: p.sku as string,
    price: Number(p.price ?? 0),
    cost: Number(p.cost ?? 0),
    stock: Number(p.stock ?? 0),
    reorderPoint: Number(p.reorder_point ?? 10),
    unit: (p.unit as string) ?? 'pcs',
    batchNumber: (p.batch_number as string) ?? undefined,
    expiryDate: p.expiry_date ? String(p.expiry_date).slice(0, 10) : undefined,
    businessType: (p.business_type as BusinessType) ?? 'retail',
    requiresPrescription: Boolean(p.requires_prescription),
  } as Product;
}

export async function fetchProductsFromApi(): Promise<Product[]> {
  const raw = await api.getAllProducts();
  return (raw as Array<Record<string, unknown>>).map(mapProduct);
}

export async function fetchCustomersFromApi(): Promise<Customer[]> {
  const raw = await api.getAllCustomers();
  return (raw as Array<Record<string, unknown>>).map(mapCustomer);
}

/** Keep local POS-created rows until the server returns the same phone/id. */
export function mergeCustomersFromApi(existing: Customer[], fromApi: Customer[]): Customer[] {
  const apiIds = new Set(fromApi.map(c => c.id));
  const apiPhones = new Set(fromApi.map(c => c.phone.replace(/\s/g, '')));
  const pendingLocal = existing.filter(c => {
    if (apiIds.has(c.id)) return false;
    const normalized = c.phone.replace(/\s/g, '');
    if (apiPhones.has(normalized)) return false;
    return c.id.startsWith('cust-');
  });
  return [...fromApi, ...pendingLocal];
}

export function mapCustomer(c: Record<string, unknown>): Customer {
  return {
    id: c.id as string,
    name: c.name as string,
    phone: c.phone as string,
    email: (c.email as string) ?? '',
    address: (c.address as string) ?? '',
    creditLimit: (c.credit_limit as number) ?? 0,
    balance: (c.balance as number) ?? 0,
    joinedDate: String(c.created_at ?? '').slice(0, 10),
    loyaltyTier: (c.loyalty_tier as Customer['loyaltyTier']) ?? 'Bronze',
    loyaltyPoints: (c.loyalty_points as number) ?? 0,
    riskScore: 'Low',
    dunningStage: (c.dunning_stage as Customer['dunningStage']) ?? 'cleared',
    daysOverdue: 0,
    lastPurchaseDate: '',
    totalPurchases: 0,
    avatarColor: 'bg-brand-600',
  };
}

export function mapSupplier(s: Record<string, unknown>): Supplier {
  return {
    id: s.id as string,
    name: s.name as string,
    contactPerson: (s.contact_person as string) ?? '',
    phone: (s.phone as string) ?? '',
    email: (s.email as string) ?? '',
    category: (s.category as string) ?? '',
    paymentTerms: (s.payment_terms as string) ?? 'Net 30 Days',
    outstandingPayable: (s.outstanding_payable as number) ?? 0,
    leadTimeDays: (s.lead_time_days as number) ?? 7,
    rating: (s.rating as number) ?? 5,
    balance: (s.outstanding_payable as number) ?? 0,
    totalPurchases: 0,
  } as Supplier;
}

export function mapBranch(b: Record<string, unknown>): StoreBranch {
  return {
    id: b.id as string,
    name: b.name as string,
    code: b.code as string,
    type: (b.branch_type as StoreBranch['type']) ?? 'main_hq',
    status: (b.status as StoreBranch['status']) ?? 'active',
    region: (b.region as string) ?? '',
    district: (b.district as string) ?? '',
    address: (b.address as string) ?? '',
    phone: (b.phone as string) ?? '',
    email: '',
    staffCount: 0,
    activeRegistersCount: 1,
    dailyGmvTzs: 0,
    monthlyGmvTzs: 0,
    stockCount: 0,
    stockValuationTzs: 0,
    traEfdSerial: '',
    openingHours: '08:00 - 20:00',
    createdDate: String(b.created_at ?? '').slice(0, 10),
  };
}

export function mapExpense(e: Record<string, unknown>): ExpenseItem {
  const dt = String(e.expense_date ?? '');
  return {
    id: e.id as string,
    date: dt.slice(0, 10),
    time: dt.length > 10 ? dt.slice(11, 16) : '09:00',
    title: e.title as string,
    category: (e.category as ExpenseItem['category']) ?? 'other',
    amount: (e.amount as number) ?? 0,
    paymentMethod: (e.payment_method as ExpenseItem['paymentMethod']) ?? 'cash_drawer',
    recipient: (e.recipient as string) ?? '',
    recordedBy: 'System',
    status: (e.status as ExpenseItem['status']) ?? 'paid',
  };
}

export function mapEvent(ev: Record<string, unknown>): CalendarEvent {
  return {
    id: ev.id as string,
    title: ev.title as string,
    category: (ev.category as CalendarEvent['category']) ?? 'general',
    date: String(ev.event_date ?? '').slice(0, 10),
    time: (ev.event_time as string) ?? '09:00',
    priority: (ev.priority as CalendarEvent['priority']) ?? 'medium',
    description: (ev.description as string) ?? '',
    assignedTo: (ev.assigned_to as string) ?? '',
    completed: Boolean(ev.completed),
  };
}

const DEFAULT_STAFF_PERMISSIONS: Record<StaffRole, StaffPermissions> = {
  Owner: {
    canSellPOS: true, canGiveCredit: true, canModifyInventory: true,
    canViewProfitReports: true, canManageSuppliers: true, canApproveDiscounts: true,
    canOverridePrices: true, canVoidReceipts: true, canPerformDailyClosing: true, canAccessSuperAdmin: false,
  },
  Manager: {
    canSellPOS: true, canGiveCredit: true, canModifyInventory: true,
    canViewProfitReports: true, canManageSuppliers: true, canApproveDiscounts: true,
    canOverridePrices: true, canVoidReceipts: true, canPerformDailyClosing: true, canAccessSuperAdmin: false,
  },
  Pharmacist: {
    canSellPOS: true, canGiveCredit: true, canModifyInventory: true,
    canViewProfitReports: false, canManageSuppliers: true, canApproveDiscounts: true,
    canOverridePrices: true, canVoidReceipts: true, canPerformDailyClosing: false, canAccessSuperAdmin: false,
  },
  Cashier: {
    canSellPOS: true, canGiveCredit: false, canModifyInventory: false,
    canViewProfitReports: false, canManageSuppliers: false, canApproveDiscounts: false,
    canOverridePrices: false, canVoidReceipts: false, canPerformDailyClosing: true, canAccessSuperAdmin: false,
  },
  Storekeeper: {
    canSellPOS: false, canGiveCredit: false, canModifyInventory: true,
    canViewProfitReports: false, canManageSuppliers: true, canApproveDiscounts: false,
    canOverridePrices: false, canVoidReceipts: false, canPerformDailyClosing: false, canAccessSuperAdmin: false,
  },
  Accountant: {
    canSellPOS: false, canGiveCredit: true, canModifyInventory: true,
    canViewProfitReports: true, canManageSuppliers: true, canApproveDiscounts: false,
    canOverridePrices: false, canVoidReceipts: false, canPerformDailyClosing: true, canAccessSuperAdmin: false,
  },
};

export function resolveStaffPermissions(
  staff: Pick<StaffMember, 'role' | 'permissions'>,
): StaffPermissions {
  const defaults = DEFAULT_STAFF_PERMISSIONS[staff.role] ?? DEFAULT_STAFF_PERMISSIONS.Cashier;
  const fromApi = staff.permissions as Partial<StaffPermissions> | undefined;
  if (!fromApi || typeof fromApi !== 'object') return defaults;
  return { ...defaults, ...fromApi };
}

export function mapStaff(s: Record<string, unknown>): StaffMember {
  const role = (s.role as StaffMember['role']) ?? 'Cashier';
  return {
    id: s.id as string,
    name: s.name as string,
    role,
    email: (s.email as string) ?? '',
    phone: (s.phone as string) ?? '',
    active: Boolean(s.active ?? true),
    joinedDate: new Date().toISOString().slice(0, 10),
    branch: 'HQ',
    shift: 'Day',
    todaySalesCount: 0,
    todayRevenueTzs: 0,
    lastActive: new Date().toISOString().slice(0, 10),
    permissions: resolveStaffPermissions({
      role,
      permissions: s.permissions as StaffPermissions | undefined,
    }),
  };
}

export function mapPurchaseOrder(po: Record<string, unknown>): PurchaseOrder {
  const items = (po.items as Array<Record<string, unknown>>) ?? [];
  return {
    id: po.id as string,
    poNumber: (po.po_number as string) ?? '',
    supplierId: (po.supplier_id as string) ?? '',
    supplierName: (po.supplier_name as string) ?? '',
    dateCreated: String(po.created_at ?? '').slice(0, 10),
    expectedDate: String(po.created_at ?? '').slice(0, 10),
    status: (po.status as PurchaseOrder['status']) ?? 'draft',
    items: items.map(i => ({
      productId: (i.product_id as string) ?? undefined,
      productName: (i.product_name as string) ?? '',
      quantity: (i.quantity as number) ?? 0,
      costPrice: (i.unit_cost as number) ?? 0,
      total: (i.total as number) ?? 0,
    })),
    subtotal: (po.subtotal as number) ?? 0,
    totalAmount: (po.total_amount as number) ?? 0,
    paidAmount: (po.paid_amount as number) ?? 0,
  };
}

export function mapSale(s: Record<string, unknown>): SaleTransaction {
  const items = (s.items as Array<Record<string, unknown>>) ?? [];
  return {
    id: s.id as string,
    receiptNumber: (s.receipt_number as string) ?? '',
    date: String(s.created_at ?? '').replace('T', ' ').slice(0, 16),
    customerId: (s.customer_id as string) ?? undefined,
    customerName: (s.customer_name as string) ?? 'Walk-in',
    items: items.map(i => ({
      productId: (i.product_id as string) ?? '',
      productName: (i.product_name as string) ?? '',
      quantity: (i.quantity as number) ?? 0,
      unitPrice: (i.unit_price as number) ?? 0,
      total: (i.total as number) ?? 0,
    })),
    subtotal: (s.subtotal as number) ?? 0,
    vatAmount: (s.vat_amount as number) ?? 0,
    total: (s.total as number) ?? 0,
    paidAmount: (s.paid_amount as number) ?? 0,
    balanceRemaining: (s.balance_remaining as number) ?? 0,
    payments: (s.payments as SaleTransaction['payments']) ?? [],
    type: (s.sale_type as SaleTransaction['type']) ?? 'full',
    cashierName: (s.cashier_name as string) ?? '',
    traEfdSignature: (s.tra_efd_signature as string) ?? '',
    status: (s.status as SaleTransaction['status']) ?? 'completed',
  };
}

export function mapStockMovement(m: Record<string, unknown>): StockMovement {
  return {
    id: m.id as string,
    date: String(m.created_at ?? '').replace('T', ' ').slice(0, 16),
    productId: (m.product_id as string) ?? '',
    productName: (m.product_name as string) ?? '',
    sku: (m.sku as string) ?? '',
    type: (m.movement_type as StockMovement['type']) ?? 'in_adjustment',
    quantity: (m.quantity as number) ?? 0,
    previousStock: (m.previous_stock as number) ?? 0,
    newStock: (m.new_stock as number) ?? 0,
    unitCost: 0,
    totalValuation: 0,
    operatorName: (m.operator_name as string) ?? '',
    notes: (m.notes as string) ?? undefined,
  };
}

export function mapAdminTenant(t: Record<string, unknown>): TenantStore {
  return {
    id: t.id as string,
    name: t.name as string,
    ownerName: (t.owner_name as string) ?? '',
    ownerEmail: (t.owner_email as string) ?? '',
    ownerPhone: (t.owner_phone as string) ?? '',
    type: (t.business_type as TenantStore['type']) ?? 'retail',
    region: (t.region as string) ?? '',
    district: (t.district as string) ?? '',
    plan: (t.plan as TenantStore['plan']) ?? 'biashara_pro',
    status: (t.status as TenantStore['status']) ?? 'active',
    traEfdDeviceSerial: (t.tra_efd_serial as string) ?? '',
    tinNumber: (t.tin_number as string) ?? '',
    licenseNumber: (t.license_number as string) ?? '',
    branchesCount: (t.branches_count as number) ?? 0,
    staffCount: 0,
    monthlyGmvTzs: (t.monthly_revenue as number) ?? 0,
    mrrTzs: (t.mrr_tzs as number) ?? 0,
    createdAt: String(t.created_at ?? '').slice(0, 10),
    lastSyncTime: String(t.created_at ?? '').slice(0, 10),
    subscriptionExpiry: String(t.subscription_expiry ?? '').slice(0, 10) || new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10),
    kycDocumentsVerified: (t.status as string) === 'active',
    autoRenew: true,
    storageUsedMb: 0,
  };
}

export async function syncTenantFromApi(): Promise<ApiSyncResult | null> {
  try {
    const profile = await api.getTenantProfile();
    const [
      productsResult,
      customersResult,
      suppliersResult,
      branchesResult,
      expensesResult,
      eventsResult,
      staffResult,
      posResult,
      salesResult,
      movementsResult,
    ] = await Promise.allSettled([
      api.getAllProducts(),
      api.getAllCustomers(),
      api.getSuppliers(),
      api.getBranches(),
      api.getExpenses(),
      api.getCalendarEvents(),
      api.getStaff(),
      api.getPurchaseOrders(),
      api.getAllSales(),
      api.getStockMovements(),
    ]);

    const unwrap = <T>(result: PromiseSettledResult<T>, fallback: T): T =>
      result.status === 'fulfilled' ? result.value : fallback;

    const productsRaw = unwrap(productsResult, [] as Array<Record<string, unknown>>);
    const customersRaw = unwrap(customersResult, [] as Array<Record<string, unknown>>);
    const suppliersRaw = unwrap(suppliersResult, [] as Array<Record<string, unknown>>);
    const branchesRaw = unwrap(branchesResult, [] as Array<Record<string, unknown>>);
    const expensesRaw = unwrap(expensesResult, [] as Array<Record<string, unknown>>);
    const eventsRaw = unwrap(eventsResult, [] as Array<Record<string, unknown>>);
    const staffRaw = unwrap(staffResult, [] as Array<Record<string, unknown>>);
    const posRaw = unwrap(posResult, [] as Array<Record<string, unknown>>);
    const salesRaw = unwrap(salesResult, [] as Array<Record<string, unknown>>);
    const movementsRaw = unwrap(movementsResult, [] as Array<Record<string, unknown>>);

    return {
      businessType: profile.business_type as BusinessType,
      businessName: profile.business_name,
      plan: (profile as { plan?: string }).plan as import('@/types/v1').SaaSPlanTier | undefined,
      subscriptionExpiry: String((profile as { subscription_expiry?: string }).subscription_expiry ?? '').slice(0, 10) || undefined,
      tenantStatus: (profile as { status?: string }).status,
      products: productsRaw.map(mapProduct),
      customers: customersRaw.map(mapCustomer),
      customersFetchOk: customersResult.status === 'fulfilled',
      suppliers: suppliersRaw.map(mapSupplier),
      branches: branchesRaw.map(mapBranch),
      expenses: expensesRaw.map(mapExpense),
      events: eventsRaw.map(mapEvent),
      staff: staffRaw.map(mapStaff),
      purchaseOrders: posRaw.map(mapPurchaseOrder),
      sales: salesRaw.map(mapSale),
      stockMovements: movementsRaw.map(mapStockMovement),
    };
  } catch {
    return null;
  }
}

export function mapSubscriptionPayment(raw: Record<string, unknown>): SaaSTransaction {
  return {
    id: String(raw.id),
    storeId: String(raw.store_id),
    storeName: String(raw.store_name),
    plan: raw.plan as SaaSTransaction['plan'],
    amountTzs: Number(raw.amount_tzs ?? 0),
    paymentMethod: (raw.payment_method as SaaSTransaction['paymentMethod']) ?? 'M-Pesa',
    reference: String(raw.reference ?? ''),
    date: String(raw.date ?? ''),
    status: (raw.status as SaaSTransaction['status']) ?? 'completed',
    billingCycle: (raw.billing_cycle as SaaSTransaction['billingCycle']) ?? 'monthly',
  };
}

export function mapBroadcast(raw: Record<string, unknown>): PlatformBroadcast {
  return {
    id: String(raw.id),
    title: String(raw.title),
    message: String(raw.message),
    targetAudience: (raw.target_audience as PlatformBroadcast['targetAudience']) ?? 'all',
    targetRegion: String(raw.target_region ?? ''),
    channel: (raw.channel as PlatformBroadcast['channel']) ?? 'both',
    sentAt: String(raw.sent_at ?? ''),
    sentBy: String(raw.sent_by ?? 'Provider Admin'),
    deliveryCount: Number(raw.delivery_count ?? 0),
    status: (raw.status as PlatformBroadcast['status']) ?? 'sent',
  };
}

export async function syncAdminFromApi(): Promise<{
  tenants: TenantStore[];
  metrics: Record<string, unknown>;
  payments: SaaSTransaction[];
  broadcasts: PlatformBroadcast[];
} | null> {
  try {
    const [tenantsRaw, metrics, paymentsRaw, broadcastsRaw] = await Promise.all([
      api.getAdminTenants(),
      api.getAdminMetrics(),
      api.getSubscriptionPayments().catch(() => []),
      api.getAdminBroadcasts().catch(() => []),
    ]);
    return {
      tenants: tenantsRaw.map(mapAdminTenant),
      metrics,
      payments: (paymentsRaw as Array<Record<string, unknown>>).map(mapSubscriptionPayment),
      broadcasts: (broadcastsRaw as Array<Record<string, unknown>>).map(mapBroadcast),
    };
  } catch {
    return null;
  }
}

export interface DashboardStats {
  todayRevenue: number;
  todaySalesCount: number;
  totalProducts: number;
  lowStockCount: number;
  expiringSoonCount: number;
  totalCustomers: number;
  outstandingReceivables: number;
  outstandingPayables: number;
  monthlyRevenue: number;
  topProducts: Array<{ name: string; quantity: number; revenue: number }>;
}

export function mapDashboardStats(raw: Record<string, unknown>): DashboardStats {
  const top = (raw.top_products as Array<Record<string, unknown>>) ?? [];
  return {
    todayRevenue: Number(raw.today_revenue ?? 0),
    todaySalesCount: Number(raw.today_sales_count ?? 0),
    totalProducts: Number(raw.total_products ?? 0),
    lowStockCount: Number(raw.low_stock_count ?? 0),
    expiringSoonCount: Number(raw.expiring_soon_count ?? 0),
    totalCustomers: Number(raw.total_customers ?? 0),
    outstandingReceivables: Number(raw.outstanding_receivables ?? 0),
    outstandingPayables: Number(raw.outstanding_payables ?? 0),
    monthlyRevenue: Number(raw.monthly_revenue ?? 0),
    topProducts: top.map(p => ({
      name: String(p.name ?? p.product_name ?? ''),
      quantity: Number(p.quantity ?? 0),
      revenue: Number(p.revenue ?? p.total ?? 0),
    })),
  };
}

export async function fetchDashboardStats(): Promise<DashboardStats | null> {
  try {
    const raw = await api.getDashboardStats();
    return mapDashboardStats(raw);
  } catch {
    return null;
  }
}

export function productToApiPayload(p: Partial<Product> & { name: string }) {
  return {
    name: p.name,
    category: p.category,
    sku: p.sku,
    price: p.price,
    cost: p.cost,
    stock: p.stock,
    reorder_point: p.reorderPoint,
    unit: p.unit,
    batch_number: p.batchNumber?.trim() || undefined,
    expiry_date: optionalApiDate(p.expiryDate),
    requires_prescription: p.requiresPrescription,
    business_type: p.businessType,
    metadata_json: (p as { metadata_json?: Record<string, unknown> }).metadata_json,
  };
}

export function customerToApiPayload(c: Partial<Customer> & { name: string }) {
  return {
    name: c.name.trim(),
    phone: (c.phone ?? '').trim(),
    email: (c.email ?? '').trim(),
    address: (c.address ?? '').trim(),
    credit_limit: c.creditLimit ?? 0,
    notes: (c as { notes?: string }).notes?.trim() || undefined,
  };
}

export function supplierToApiPayload(s: Partial<Supplier> & { name: string }) {
  return {
    name: s.name,
    contact_person: s.contactPerson,
    phone: s.phone,
    email: s.email,
    category: s.category,
    payment_terms: s.paymentTerms,
    lead_time_days: s.leadTimeDays,
    rating: s.rating,
  };
}

export function expenseToApiPayload(e: { title: string; category: string; amount: number; paymentMethod?: string; recipient?: string; notes?: string }) {
  return {
    title: e.title,
    category: e.category,
    amount: e.amount,
    payment_method: e.paymentMethod,
    recipient: e.recipient,
    notes: e.notes,
  };
}

export function eventToApiPayload(ev: Partial<CalendarEvent> & { title: string; date: string }) {
  return {
    title: ev.title,
    category: ev.category,
    event_date: ev.date,
    event_time: ev.time,
    priority: ev.priority,
    description: ev.description,
    assigned_to: ev.assignedTo,
  };
}

export function saleToApiPayload(sale: SaleTransaction, options?: { finalize?: boolean }) {
  const finalize =
    options?.finalize ??
    (sale.status === 'completed' || sale.status === 'pending_credit');
  return {
    items: sale.items.map(i => ({
      product_id: i.productId,
      product_name: i.productName,
      quantity: i.quantity,
      unit_price: i.unitPrice,
      total: i.total,
      discount_percent: i.discountPercent ?? 0,
      original_unit_price: i.originalUnitPrice ?? i.unitPrice,
    })),
    customer_id: sale.customerId || null,
    customer_name: sale.customerName,
    payments: (sale.payments ?? []).map(p => ({
      method: p.method,
      amount: p.amount,
      reference: p.reference,
    })),
    sale_type: sale.type,
    branch_id: sale.branchId || null,
    client_id: sale.id,
    finalize,
  };
}
