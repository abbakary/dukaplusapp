import { fetchAllPages, unwrapPage } from './pagination';
import { getApiBaseUrl } from './apiConfig';

const API_BASE = getApiBaseUrl();
const DEFAULT_TOKEN_DAYS = 3;
const TOKEN_EXPIRES_KEY = 'duka_token_expires';

class ApiClient {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;

  setTokens(access: string, refresh: string, expiresInDays = DEFAULT_TOKEN_DAYS) {
    this.accessToken = access;
    this.refreshToken = refresh;
    localStorage.setItem('duka_access', access);
    localStorage.setItem('duka_refresh', refresh);
    const expiresAt = Date.now() + expiresInDays * 24 * 60 * 60 * 1000;
    localStorage.setItem(TOKEN_EXPIRES_KEY, String(expiresAt));
  }

  loadTokens() {
    this.accessToken = localStorage.getItem('duka_access');
    this.refreshToken = localStorage.getItem('duka_refresh');
  }

  hasValidSession(): boolean {
    this.loadTokens();
    if (!this.accessToken) return false;
    const raw = localStorage.getItem(TOKEN_EXPIRES_KEY);
    if (raw && Date.now() > Number(raw)) return false;
    return true;
  }

  clearTokens() {
    this.accessToken = null;
    this.refreshToken = null;
    localStorage.removeItem('duka_access');
    localStorage.removeItem('duka_refresh');
    localStorage.removeItem('duka_user');
    localStorage.removeItem(TOKEN_EXPIRES_KEY);
  }

  private async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    this.loadTokens();
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string>),
    };
    if (this.accessToken) headers['Authorization'] = `Bearer ${this.accessToken}`;

    let res: Response;
    try {
      res = await fetch(`${API_BASE}${path}`, { ...options, headers });
    } catch (error) {
      throw new Error(
        error instanceof Error ? error.message : 'Network request failed',
      );
    }

    if (res.status === 401 && this.refreshToken) {
      const refreshed = await this.tryRefresh();
      if (refreshed) {
        headers['Authorization'] = `Bearer ${this.accessToken}`;
        res = await fetch(`${API_BASE}${path}`, { ...options, headers });
      }
    }

    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(typeof err.detail === 'string' ? err.detail : JSON.stringify(err.detail) || 'Request failed');
    }
    if (res.status === 204) return undefined as T;
    return res.json();
  }

  private async tryRefresh(): Promise<boolean> {
    try {
      const res = await fetch(`${API_BASE}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refresh_token: this.refreshToken }),
      });
      if (!res.ok) return false;
      const data = await res.json();
      this.setTokens(data.access_token, data.refresh_token, data.expires_in_days ?? DEFAULT_TOKEN_DAYS);
      return true;
    } catch {
      return false;
    }
  }

  // Auth
  login(email: string, password: string) {
    return this.request<{ access_token: string; refresh_token: string; expires_in_days?: number }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password, device_info: navigator.userAgent }),
    });
  }
  register(data: Record<string, string>) {
    return this.request('/auth/register', { method: 'POST', body: JSON.stringify(data) });
  }
  getMe() {
    return this.request<Record<string, unknown>>('/auth/me');
  }
  logout() {
    if (this.refreshToken) {
      return this.request('/auth/logout', {
        method: 'POST',
        body: JSON.stringify({ refresh_token: this.refreshToken }),
      });
    }
    return Promise.resolve();
  }

  // Business core
  getDashboardStats() {
    return this.request<Record<string, unknown>>('/dashboard/stats');
  }
  getAnalyticsSnapshot(range: 'month' | 'quarter' | 'year' | 'all' = 'month') {
    return this.request<Record<string, unknown>>(`/analytics/snapshot?range=${range}`);
  }
  getProductsPage(params?: Record<string, string | number | boolean>) {
    const qs = params
      ? '?' + new URLSearchParams(Object.entries(params).map(([k, v]) => [k, String(v)])).toString()
      : '';
    return this.request<unknown>(`/products${qs}`).then(r => unwrapPage<Record<string, unknown>>(r));
  }
  async getProducts(params?: Record<string, string | number | boolean>) {
    const page = await this.getProductsPage({ ...params, limit: params?.limit ?? 500, skip: params?.skip ?? 0 });
    return page.items;
  }
  async getAllProducts() {
    return fetchAllPages((skip, limit) => this.getProductsPage({ skip, limit }));
  }
  createProduct(data: Record<string, unknown>) {
    return this.request('/products', { method: 'POST', body: JSON.stringify(data) });
  }
  updateProduct(id: string, data: Record<string, unknown>) {
    return this.request(`/products/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
  }
  getCustomersPage(search?: string, skip = 0, limit = 500) {
    const params = new URLSearchParams({ skip: String(skip), limit: String(limit) });
    if (search) params.set('search', search);
    return this.request<unknown>(`/customers?${params}`).then(r => unwrapPage<Record<string, unknown>>(r));
  }
  async getCustomers(search?: string) {
    const page = await this.getCustomersPage(search, 0, 500);
    return page.items;
  }
  async getAllCustomers() {
    return fetchAllPages((skip, limit) => this.getCustomersPage(undefined, skip, limit));
  }
  createCustomer(data: Record<string, unknown>) {
    return this.request('/customers', { method: 'POST', body: JSON.stringify(data) });
  }
  updateCustomer(id: string, data: Record<string, unknown>) {
    return this.request(`/customers/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
  }
  createSale(data: Record<string, unknown>) {
    return this.request<Record<string, unknown>>('/sales', { method: 'POST', body: JSON.stringify(data) });
  }
  getSalesPage(status?: string, skip = 0, limit = 500) {
    const params = new URLSearchParams({ skip: String(skip), limit: String(limit) });
    if (status) params.set('status', status);
    return this.request<unknown>(`/sales?${params}`).then(r => unwrapPage<Record<string, unknown>>(r));
  }
  async getSales(status?: string) {
    const page = await this.getSalesPage(status, 0, 500);
    return page.items;
  }
  async getAllSales() {
    return fetchAllPages((skip, limit) => this.getSalesPage(undefined, skip, limit));
  }
  finalizeSale(id: string, data: Record<string, unknown>) {
    return this.request<Record<string, unknown>>(`/sales/${id}/finalize`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }
  adjustStock(data: Record<string, unknown>) {
    return this.request('/stock/adjust', { method: 'POST', body: JSON.stringify(data) });
  }
  getStockMovements(productId?: string) {
    const qs = productId ? `?product_id=${productId}` : '';
    return this.request<Array<Record<string, unknown>>>(`/stock/movements${qs}`);
  }
  syncBatch(items: Array<Record<string, unknown>>) {
    return this.request('/sync/batch', { method: 'POST', body: JSON.stringify({ items }) });
  }

  // Tenant
  getTenantProfile() {
    return this.request<{
      business_name: string;
      business_type: string;
      workplace: import('@/lib/businessProfiles').BusinessWorkplace;
    }>('/tenant/profile');
  }
  getBusinessTypes() {
    return this.request<{ types: Array<{ id: string; label_sw: string; label_en: string; icon: string }> }>('/tenant/business-types');
  }

  // Extended
  getSuppliers() { return this.request<Array<Record<string, unknown>>>('/suppliers'); }
  createSupplier(data: Record<string, unknown>) { return this.request('/suppliers', { method: 'POST', body: JSON.stringify(data) }); }
  updateSupplier(id: string, data: Record<string, unknown>) { return this.request(`/suppliers/${id}`, { method: 'PATCH', body: JSON.stringify(data) }); }
  getBranches() { return this.request<Array<Record<string, unknown>>>('/branches'); }
  getStaff() { return this.request<Array<Record<string, unknown>>>('/staff'); }
  createStaff(data: Record<string, unknown>) { return this.request('/staff', { method: 'POST', body: JSON.stringify(data) }); }
  updateStaff(id: string, data: Record<string, unknown>) { return this.request(`/staff/${id}`, { method: 'PATCH', body: JSON.stringify(data) }); }
  claimDailyStipend(data?: { food_amount?: number; transport_amount?: number }) {
    return this.request<Record<string, unknown>>('/staff/me/claim-stipend', {
      method: 'POST',
      body: JSON.stringify(data ?? {}),
    });
  }
  getExpenses() { return this.request<Array<Record<string, unknown>>>('/expenses'); }
  createExpense(data: Record<string, unknown>) { return this.request('/expenses', { method: 'POST', body: JSON.stringify(data) }); }
  updateExpense(id: string, data: Record<string, unknown>) { return this.request(`/expenses/${id}`, { method: 'PATCH', body: JSON.stringify(data) }); }
  deleteExpense(id: string) { return this.request(`/expenses/${id}`, { method: 'DELETE' }); }
  getCalendarEvents() { return this.request<Array<Record<string, unknown>>>('/calendar/events'); }
  createCalendarEvent(data: Record<string, unknown>) { return this.request('/calendar/events', { method: 'POST', body: JSON.stringify(data) }); }
  updateCalendarEvent(id: string, data: Record<string, unknown>) { return this.request(`/calendar/events/${id}`, { method: 'PATCH', body: JSON.stringify(data) }); }
  deleteCalendarEvent(id: string) { return this.request(`/calendar/events/${id}`, { method: 'DELETE' }); }
  getPurchaseOrders() { return this.request<Array<Record<string, unknown>>>('/purchase-orders'); }
  createPurchaseOrder(data: Record<string, unknown>) { return this.request('/purchase-orders', { method: 'POST', body: JSON.stringify(data) }); }
  receivePurchaseOrder(id: string, notes?: string) {
    return this.request(`/purchase-orders/${id}/receive`, { method: 'POST', body: JSON.stringify({ notes }) });
  }

  // Workplace (tables, KOT, appointments) — branch-scoped per spec Part 4B / Part 7
  getWorkplaceState(branchId?: string) {
    const qs =
      branchId && branchId !== 'all'
        ? `?branch_id=${encodeURIComponent(branchId)}`
        : '';
    return this.request<Record<string, unknown>>(`/workplace/state${qs}`);
  }
  updateWorkplaceState(data: Record<string, unknown>, branchId?: string) {
    const qs =
      branchId && branchId !== 'all'
        ? `?branch_id=${encodeURIComponent(branchId)}`
        : '';
    return this.request(`/workplace/state${qs}`, { method: 'PUT', body: JSON.stringify(data) });
  }

  // Super admin
  getAdminMetrics() { return this.request<Record<string, unknown>>('/admin/metrics'); }
  getAdminTenants(params?: { status_filter?: string; business_type?: string }) {
    const qs = params ? '?' + new URLSearchParams(Object.entries(params).filter(([, v]) => v).map(([k, v]) => [k, v!])).toString() : '';
    return this.request<Array<Record<string, unknown>>>(`/admin/tenants${qs}`);
  }
  approveTenantKyc(id: string) { return this.request(`/admin/tenants/${id}/approve-kyc`, { method: 'POST' }); }
  suspendTenant(id: string) { return this.request(`/admin/tenants/${id}/suspend`, { method: 'POST' }); }
  reactivateTenant(id: string) { return this.request(`/admin/tenants/${id}/reactivate`, { method: 'POST' }); }
  setTenantGrace(id: string) { return this.request(`/admin/tenants/${id}/grace`, { method: 'POST' }); }
  updateAdminTenant(id: string, data: Record<string, unknown>) {
    return this.request(`/admin/tenants/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
  }

  getPublicShowcase() {
    return this.request<Array<Record<string, unknown>>>('/platform/showcase');
  }
  getPublicPlans() {
    return this.request<Array<Record<string, unknown>>>('/platform/plans');
  }
  getAdminPlans() {
    return this.request<Array<Record<string, unknown>>>('/admin/plans');
  }
  updateAdminPlan(id: string, data: Record<string, unknown>) {
    return this.request<Record<string, unknown>>(`/admin/plans/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
  }
  resetAdminPlans() {
    return this.request<Array<Record<string, unknown>>>('/admin/plans/reset', { method: 'POST' });
  }
  getSubscriptionPayments() {
    return this.request<Array<Record<string, unknown>>>('/admin/subscription-payments');
  }
  recordSubscriptionPayment(data: Record<string, unknown>) {
    return this.request<Record<string, unknown>>('/admin/subscription-payments', { method: 'POST', body: JSON.stringify(data) });
  }
  getAdminBroadcasts() {
    return this.request<Array<Record<string, unknown>>>('/admin/broadcasts');
  }
  sendAdminBroadcast(data: Record<string, unknown>) {
    return this.request<Record<string, unknown>>('/admin/broadcasts', { method: 'POST', body: JSON.stringify(data) });
  }
  getTenantSettings() {
    return this.request<{ document_config: Record<string, unknown>; business_settings: Record<string, unknown> }>('/tenant/settings');
  }
  getDocumentCatalog() {
    return this.request<{
      templates: Array<{ id: string; document_type: string; name: string; name_sw: string; layout: string; popular?: boolean }>;
      default_active: Record<string, string>;
      type_labels: Record<string, { en: string; sw: string }>;
    }>('/tenant/documents/catalog');
  }
  updateTenantSettings(data: { document_config?: Record<string, unknown>; business_settings?: Record<string, unknown> }) {
    return this.request('/tenant/settings', { method: 'PUT', body: JSON.stringify(data) });
  }
  uploadDocumentLogo(imageBase64: string) {
    return this.request<{ document_config: Record<string, unknown>; business_settings: Record<string, unknown> }>(
      '/tenant/settings/logo',
      { method: 'POST', body: JSON.stringify({ image_base64: imageBase64 }) },
    );
  }
  removeDocumentLogo() {
    return this.request<{ document_config: Record<string, unknown>; business_settings: Record<string, unknown> }>(
      '/tenant/settings/logo',
      { method: 'DELETE' },
    );
  }
  getAdminShowcase() {
    return this.request<Array<Record<string, unknown>>>('/admin/showcase');
  }
  createShowcaseItem(data: Record<string, unknown>) {
    return this.request<Record<string, unknown>>('/admin/showcase', { method: 'POST', body: JSON.stringify(data) });
  }
  updateShowcaseItem(id: string, data: Record<string, unknown>) {
    return this.request<Record<string, unknown>>(`/admin/showcase/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
  }
  deleteShowcaseItem(id: string) {
    return this.request(`/admin/showcase/${id}`, { method: 'DELETE' });
  }
}

export const api = new ApiClient();
