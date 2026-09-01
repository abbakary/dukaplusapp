import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { api } from '@/lib/api';
import {
  DocumentType,
  TenantDocumentConfig,
  defaultTenantDocumentConfig,
  loadTenantDocumentConfig,
  saveTenantDocumentConfig,
  getActiveTemplate,
  templatesByType,
  allTemplatesForTenant,
  DocumentBranding,
  DocumentTemplate,
} from '@/lib/documentTemplates';

interface DocumentTemplateContextValue {
  config: TenantDocumentConfig;
  loading: boolean;
  setActiveTemplate: (type: DocumentType, templateId: string) => void;
  updateBranding: (patch: Partial<DocumentBranding>) => void;
  uploadLogo: (file: File) => Promise<void>;
  removeLogo: () => Promise<void>;
  addCustomTemplate: (tpl: DocumentTemplate) => void;
  resetConfig: () => void;
  getActive: (type: DocumentType) => DocumentTemplate;
  listForType: (type: DocumentType) => DocumentTemplate[];
  allTemplates: DocumentTemplate[];
}

const DocumentTemplateContext = createContext<DocumentTemplateContextValue | null>(null);

interface Props {
  tenantId?: string | null;
  businessName?: string;
  children: React.ReactNode;
}

function mapApiDocumentConfig(raw: Record<string, unknown>, businessName?: string): TenantDocumentConfig {
  const defaults = defaultTenantDocumentConfig(businessName);
  const branding = (raw.branding as Record<string, unknown>) ?? {};
  const activeIds = (raw.activeTemplateIds as Record<string, string>) ?? {};
  return {
    activeTemplateIds: { ...defaults.activeTemplateIds, ...activeIds },
    branding: {
      logoUrl: String(branding.logoUrl ?? ''),
      companyName: String(branding.companyName ?? businessName ?? ''),
      footerText: String(branding.footerText ?? defaults.branding.footerText),
      watermark: String(branding.watermark ?? ''),
      address: String(branding.address ?? ''),
      phone: String(branding.phone ?? ''),
      tinNumber: String(branding.tinNumber ?? ''),
    },
    customTemplates: (raw.customTemplates as DocumentTemplate[]) ?? [],
    updatedAt: String(raw.updatedAt ?? new Date().toISOString()),
  };
}

function readFileAsDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result ?? ''));
    reader.onerror = () => reject(reader.error ?? new Error('Failed to read file'));
    reader.readAsDataURL(file);
  });
}

export const DocumentTemplateProvider: React.FC<Props> = ({
  tenantId,
  businessName,
  children,
}) => {
  const [config, setConfig] = useState<TenantDocumentConfig>(() =>
    loadTenantDocumentConfig(tenantId, businessName),
  );
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!tenantId) {
      setConfig(loadTenantDocumentConfig(tenantId, businessName));
      return;
    }
    setLoading(true);
    api.getTenantSettings()
      .then(res => {
        const doc = res.document_config ?? {};
        if (Object.keys(doc).length) {
          const mapped = mapApiDocumentConfig(doc, businessName);
          setConfig(mapped);
          saveTenantDocumentConfig(tenantId, mapped);
        } else {
          setConfig(loadTenantDocumentConfig(tenantId, businessName));
        }
      })
      .catch(() => {
        setConfig(loadTenantDocumentConfig(tenantId, businessName));
      })
      .finally(() => setLoading(false));
  }, [tenantId, businessName]);

  const persist = useCallback(
    (updater: (prev: TenantDocumentConfig) => TenantDocumentConfig) => {
      setConfig(prev => {
        const next = updater(prev);
        saveTenantDocumentConfig(tenantId, next);
        if (tenantId) {
          void api.updateTenantSettings({
            document_config: next as unknown as Record<string, unknown>,
          }).catch(() => undefined);
        }
        return next;
      });
    },
    [tenantId],
  );

  const setActiveTemplate = useCallback(
    (type: DocumentType, templateId: string) => {
      persist(prev => ({
        ...prev,
        activeTemplateIds: { ...prev.activeTemplateIds, [type]: templateId },
        updatedAt: new Date().toISOString(),
      }));
    },
    [persist],
  );

  const updateBranding = useCallback(
    (patch: Partial<DocumentBranding>) => {
      persist(prev => ({
        ...prev,
        branding: { ...prev.branding, ...patch },
        updatedAt: new Date().toISOString(),
      }));
    },
    [persist],
  );

  const uploadLogo = useCallback(
    async (file: File) => {
      const allowed = ['image/png', 'image/jpeg', 'image/webp', 'image/gif'];
      if (!allowed.includes(file.type)) {
        throw new Error('Please choose a PNG, JPEG, WEBP, or GIF image.');
      }
      if (file.size > 512_000) {
        throw new Error('Logo must be 500 KB or smaller.');
      }
      const dataUrl = await readFileAsDataUrl(file);
      if (tenantId) {
        const res = await api.uploadDocumentLogo(dataUrl);
        const mapped = mapApiDocumentConfig(res.document_config ?? {}, businessName);
        setConfig(mapped);
        saveTenantDocumentConfig(tenantId, mapped);
      } else {
        updateBranding({ logoUrl: dataUrl });
      }
    },
    [tenantId, businessName, updateBranding],
  );

  const removeLogo = useCallback(async () => {
    if (tenantId) {
      const res = await api.removeDocumentLogo();
      const mapped = mapApiDocumentConfig(res.document_config ?? {}, businessName);
      setConfig(mapped);
      saveTenantDocumentConfig(tenantId, mapped);
    } else {
      updateBranding({ logoUrl: '' });
    }
  }, [tenantId, businessName, updateBranding]);

  const addCustomTemplate = useCallback(
    (tpl: DocumentTemplate) => {
      persist(prev => ({
        ...prev,
        customTemplates: [...prev.customTemplates.filter(t => t.id !== tpl.id), tpl],
        updatedAt: new Date().toISOString(),
      }));
    },
    [persist],
  );

  const resetConfig = useCallback(() => {
    persist(() => defaultTenantDocumentConfig(businessName));
  }, [businessName, persist]);

  const value = useMemo(
    () => ({
      config,
      loading,
      setActiveTemplate,
      updateBranding,
      uploadLogo,
      removeLogo,
      addCustomTemplate,
      resetConfig,
      getActive: (type: DocumentType) => getActiveTemplate(type, config),
      listForType: (type: DocumentType) => templatesByType(type, config),
      allTemplates: allTemplatesForTenant(config),
    }),
    [config, loading, setActiveTemplate, updateBranding, uploadLogo, removeLogo, addCustomTemplate, resetConfig],
  );

  return (
    <DocumentTemplateContext.Provider value={value}>
      {children}
    </DocumentTemplateContext.Provider>
  );
};

export function useDocumentTemplates(): DocumentTemplateContextValue {
  const ctx = useContext(DocumentTemplateContext);
  if (!ctx) {
    throw new Error('useDocumentTemplates must be used within DocumentTemplateProvider');
  }
  return ctx;
}
