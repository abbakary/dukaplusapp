export type TaxComplianceMode = 'manual' | 'tra_efd';

export interface TaxComplianceSettings {
  mode: TaxComplianceMode;
  vatEnabled: boolean;
  vatRate: number;
  pricesIncludeVat: boolean;
  discountEnabled: boolean;
  maxDiscountPercent: number;
  showDiscountOnReceipts: boolean;
  showDiscountOnDocuments: boolean;
  cartDiscountEnabled: boolean;
  priceOverrideEnabled: boolean;
  partialPaymentEnabled: boolean;
  negotiationEnabled: boolean;
  showVatOnReceipt: boolean;
  showTraSignature: boolean;
  traEfdSerial: string;
  tinNumber: string;
  vrnNumber: string;
  receiptBusinessName: string;
  receiptFooterNote: string;
}

export const DEFAULT_TAX_COMPLIANCE_SETTINGS: TaxComplianceSettings = {
  mode: 'manual',
  vatEnabled: true,
  vatRate: 0.18,
  pricesIncludeVat: false,
  discountEnabled: true,
  maxDiscountPercent: 15,
  showDiscountOnReceipts: true,
  showDiscountOnDocuments: true,
  cartDiscountEnabled: false,
  priceOverrideEnabled: false,
  partialPaymentEnabled: true,
  negotiationEnabled: true,
  showVatOnReceipt: true,
  showTraSignature: false,
  traEfdSerial: '',
  tinNumber: '',
  vrnNumber: '',
  receiptBusinessName: '',
  receiptFooterNote: '',
};

const STORAGE_PREFIX = 'dukamkononi_tax_compliance_';

export function storageKeyForTenant(tenantId?: string | null): string {
  return `${STORAGE_PREFIX}${tenantId || 'default'}`;
}

export function loadTaxComplianceSettings(
  tenantId?: string | null,
  seed?: Partial<TaxComplianceSettings>,
): TaxComplianceSettings {
  const defaults = { ...DEFAULT_TAX_COMPLIANCE_SETTINGS, ...seed };
  try {
    const raw = localStorage.getItem(storageKeyForTenant(tenantId));
    if (!raw) return defaults;
    return { ...defaults, ...JSON.parse(raw) as Partial<TaxComplianceSettings> };
  } catch {
    return defaults;
  }
}

export function saveTaxComplianceSettings(
  tenantId: string | null | undefined,
  settings: TaxComplianceSettings,
): void {
  localStorage.setItem(storageKeyForTenant(tenantId), JSON.stringify(settings));
}

export interface SaleTotalsInput {
  subtotal: number;
  discountPercent?: number;
}

export interface SaleTotalsResult {
  subtotal: number;
  discountAmount: number;
  taxableAmount: number;
  vatAmount: number;
  total: number;
}

export function calculateSaleTotals(
  { subtotal, discountPercent = 0 }: SaleTotalsInput,
  settings: TaxComplianceSettings,
): SaleTotalsResult {
  const cappedDiscount = settings.discountEnabled
    ? Math.min(Math.max(discountPercent, 0), settings.maxDiscountPercent)
    : 0;
  const discountAmount = Math.round(subtotal * (cappedDiscount / 100));
  const taxableAmount = subtotal - discountAmount;

  let vatAmount = 0;
  if (settings.vatEnabled) {
    if (settings.pricesIncludeVat) {
      vatAmount = Math.round(taxableAmount - taxableAmount / (1 + settings.vatRate));
    } else {
      vatAmount = Math.round(taxableAmount * settings.vatRate);
    }
  }

  const total = settings.pricesIncludeVat
    ? taxableAmount
    : taxableAmount + vatAmount;

  return { subtotal, discountAmount, taxableAmount, vatAmount, total };
}

export function formatVatLabel(settings: TaxComplianceSettings, isSw: boolean): string {
  if (!settings.vatEnabled) {
    return isSw ? 'Kodi (imezimwa)' : 'Tax (disabled)';
  }
  const pct = Math.round(settings.vatRate * 1000) / 10;
  return isSw ? `VAT (${pct}%)` : `VAT (${pct}%)`;
}

export function generateReceiptNumber(settings: TaxComplianceSettings): string {
  const seq = Math.floor(1000 + Math.random() * 9000);
  if (settings.mode === 'tra_efd') {
    const serial = settings.traEfdSerial.replace(/\s/g, '').slice(-6) || 'EFD';
    return `TRA-${serial}-${seq}`;
  }
  return `RCP-${new Date().getFullYear()}-${seq}`;
}

export function generateTraSignature(
  settings: TaxComplianceSettings,
  receiptNumber: string,
): string {
  if (settings.mode !== 'tra_efd' || !settings.showTraSignature) return '';
  const serial = settings.traEfdSerial.replace(/\s/g, '') || 'MANUAL';
  return `EFD-TZ-${serial.slice(-6)}-${receiptNumber.replace(/\s/g, '')}-${Date.now().toString(36).toUpperCase()}`;
}

export function getComplianceStatusLabel(settings: TaxComplianceSettings, isSw: boolean): string {
  if (settings.mode === 'tra_efd') {
    return isSw ? 'TRA EFD VFD 2.0 Synced' : 'TRA EFD VFD 2.0 Synced';
  }
  return isSw ? 'Hali ya Kawaida (Bila TRA EFD)' : 'Manual mode (no TRA EFD)';
}

export function getComplianceBadgeTone(settings: TaxComplianceSettings): 'tra' | 'manual' {
  return settings.mode === 'tra_efd' ? 'tra' : 'manual';
}

/** Cap per-line or cart discount according to tenant settings. */
export function capDiscountPercent(
  discountPercent: number,
  settings: TaxComplianceSettings,
): number {
  if (!settings.discountEnabled) return 0;
  return Math.min(Math.max(discountPercent, 0), settings.maxDiscountPercent);
}

export interface LineDiscountInput {
  unitPrice: number;
  quantity: number;
  discountPercent?: number;
}

/** Effective shelf/unit price for a cart line (override or catalog). */
export function effectiveUnitPrice(unitPrice: number, override?: number): number {
  return override != null && override > 0 ? override : unitPrice;
}

/** Subtotal after per-line discounts (respects discountEnabled + max cap). */
export function computeDiscountedSubtotal(
  lines: LineDiscountInput[],
  settings: TaxComplianceSettings,
): { subtotal: number; discountAmount: number; grossSubtotal: number } {
  let grossSubtotal = 0;
  let subtotal = 0;
  for (const line of lines) {
    const gross = line.unitPrice * line.quantity;
    grossSubtotal += gross;
    const pct = capDiscountPercent(line.discountPercent ?? 0, settings);
    subtotal += Math.round(gross * (1 - pct / 100));
  }
  return { subtotal, discountAmount: grossSubtotal - subtotal, grossSubtotal };
}
