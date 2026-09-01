import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import {
  DEFAULT_TAX_COMPLIANCE_SETTINGS,
  TaxComplianceSettings,
  loadTaxComplianceSettings,
  saveTaxComplianceSettings,
} from '@/lib/taxComplianceSettings';
import { api } from '@/lib/api';

function businessSettingsFromTax(settings: TaxComplianceSettings): Record<string, unknown> {
  return {
    discountEnabled: settings.discountEnabled,
    maxDiscountPercent: settings.maxDiscountPercent,
    showDiscountOnReceipts: settings.showDiscountOnReceipts,
    showDiscountOnDocuments: settings.showDiscountOnDocuments,
    vatEnabled: settings.vatEnabled,
    vatRate: settings.vatRate,
    mode: settings.mode,
  };
}

function mergeTaxFromBusinessSettings(base: TaxComplianceSettings, raw: Record<string, unknown>): TaxComplianceSettings {
  return {
    ...base,
    discountEnabled: raw.discountEnabled !== undefined ? Boolean(raw.discountEnabled) : base.discountEnabled,
    maxDiscountPercent: raw.maxDiscountPercent !== undefined ? Number(raw.maxDiscountPercent) : base.maxDiscountPercent,
    showDiscountOnReceipts: raw.showDiscountOnReceipts !== undefined ? Boolean(raw.showDiscountOnReceipts) : base.showDiscountOnReceipts,
    showDiscountOnDocuments: raw.showDiscountOnDocuments !== undefined ? Boolean(raw.showDiscountOnDocuments) : base.showDiscountOnDocuments,
    vatEnabled: raw.vatEnabled !== undefined ? Boolean(raw.vatEnabled) : base.vatEnabled,
    vatRate: raw.vatRate !== undefined ? Number(raw.vatRate) : base.vatRate,
    mode: (raw.mode as TaxComplianceSettings['mode']) ?? base.mode,
  };
}

interface TaxComplianceContextValue {
  settings: TaxComplianceSettings;
  updateSettings: (patch: Partial<TaxComplianceSettings>) => void;
  applySettings: (next: TaxComplianceSettings) => void;
  resetSettings: () => void;
}

const TaxComplianceContext = createContext<TaxComplianceContextValue | null>(null);

interface TaxComplianceProviderProps {
  tenantId?: string | null;
  businessName?: string;
  tinNumber?: string;
  children: React.ReactNode;
}

export const TaxComplianceProvider: React.FC<TaxComplianceProviderProps> = ({
  tenantId,
  businessName,
  tinNumber,
  children,
}) => {
  const [settings, setSettings] = useState<TaxComplianceSettings>(() =>
    loadTaxComplianceSettings(tenantId, {
      receiptBusinessName: businessName || '',
      tinNumber: tinNumber || '',
    }),
  );

  useEffect(() => {
    setSettings(loadTaxComplianceSettings(tenantId, {
      receiptBusinessName: businessName || settings.receiptBusinessName,
      tinNumber: tinNumber || settings.tinNumber,
    }));
  }, [tenantId]);

  useEffect(() => {
    if (businessName && !settings.receiptBusinessName) {
      setSettings(prev => ({ ...prev, receiptBusinessName: businessName }));
    }
  }, [businessName, settings.receiptBusinessName]);

  useEffect(() => {
    if (tinNumber && !settings.tinNumber) {
      setSettings(prev => ({ ...prev, tinNumber }));
    }
  }, [tinNumber, settings.tinNumber]);

  useEffect(() => {
    if (!tenantId) return;
    api.getTenantSettings()
      .then(res => {
        const biz = res.business_settings ?? {};
        if (Object.keys(biz).length) {
          setSettings(prev => mergeTaxFromBusinessSettings(prev, biz));
        }
      })
      .catch(() => undefined);
  }, [tenantId]);

  const persist = useCallback(
    (next: TaxComplianceSettings) => {
      setSettings(next);
      saveTaxComplianceSettings(tenantId, next);
      if (tenantId) {
        void api.updateTenantSettings({ business_settings: businessSettingsFromTax(next) }).catch(() => undefined);
      }
    },
    [tenantId],
  );

  const updateSettings = useCallback(
    (patch: Partial<TaxComplianceSettings>) => {
      persist({ ...settings, ...patch });
    },
    [persist, settings],
  );

  const applySettings = useCallback(
    (next: TaxComplianceSettings) => {
      persist(next);
    },
    [persist],
  );

  const resetSettings = useCallback(() => {
    persist({
      ...DEFAULT_TAX_COMPLIANCE_SETTINGS,
      receiptBusinessName: businessName || '',
      tinNumber: tinNumber || '',
    });
  }, [businessName, persist, tinNumber]);

  const value = useMemo(
    () => ({ settings, updateSettings, applySettings, resetSettings }),
    [applySettings, resetSettings, settings, updateSettings],
  );

  return (
    <TaxComplianceContext.Provider value={value}>
      {children}
    </TaxComplianceContext.Provider>
  );
};

export function useTaxCompliance(): TaxComplianceContextValue {
  const ctx = useContext(TaxComplianceContext);
  if (!ctx) {
    throw new Error('useTaxCompliance must be used within TaxComplianceProvider');
  }
  return ctx;
}
